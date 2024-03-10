local CommandAction = require('cylibs/actions/command')
local DisposeBag = require('cylibs/events/dispose_bag')
local ffxi_util = require('cylibs/util/ffxi_util')
local KeyAction = require('cylibs/actions/key')
local monster_util = require('cylibs/util/monster_util')
local party_util = require('cylibs/util/party_util')
local TargetAction = require('cylibs/actions/target')

local Puller = setmetatable({}, {__index = Role })
Puller.__index = Puller
Puller.__class = "Puller"

state.AutoPullMode = M{['description'] = 'Auto Pull Mode', 'Off', 'Auto','Multi','Target','Party','All'}
state.AutoPullMode:set_description('Off', "Okay, I won't pull monsters for the party.")
state.AutoPullMode:set_description('Auto', "Okay, I'll automatically pull monsters for the party.")
state.AutoPullMode:set_description('Multi', "Okay, I'll pull my own monster even if we're already fighting.")
state.AutoPullMode:set_description('Target', "Okay, I'll pull whatever monster I'm currently targeting.")
state.AutoPullMode:set_description('Party', "Okay, I'll pull monsters the party is fighting.")
state.AutoPullMode:set_description('All', "Okay, I'll pull any monster that's nearby.")

state.ApproachPullMode = M{['description'] = 'Approach Pull Mode', 'Off', 'Auto'}
state.ApproachPullMode:set_description('Auto', "Okay, I'll pull by approaching.")

function Puller.new(action_queue, target_names, spell_name, job_ability_name)
    return Puller.new(action_queue, target_names, spell_name, job_ability_name, false)
end

function Puller.new(action_queue, target_names, spell_name, job_ability_name, ranged_attack)
    local self = setmetatable(Role.new(action_queue), Puller)

    self.action_queue = action_queue
    self.action_events = {}
    self.target_names = target_names
    self.blacklist = L{}
    self.spell_name = spell_name
    self.job_ability_name = job_ability_name
    self.ranged_attack = ranged_attack
    self.approach = spell_name == nil and job_ability_name == nil and ranged_attack == false
    self.pull_settings = {}
    self.pull_settings.Spells = L{}
    if spell_name then
        self.pull_settings.Spells = L{ Spell.new(spell_name) }
    end
    self.pull_settings.JobAbilities = L{}
    if job_ability_name then
        self.pull_settings.JobAbilities = L{ JobAbility.new(job_ability_name) }
    end
    self.out_of_range_counter = 0
    self.last_pull_time = os.time()
    self.last_target_check_time = os.time()
    self.no_pull_counter = 0

    self.dispose_bag = DisposeBag.new()

    return self
end

function Puller:destroy()
    Role.destroy(self)

    for _,event in pairs(self.action_events) do
        windower.unregister_event(event)
    end

    self.dispose_bag:destroy()
end

function Puller:on_add()
    self.dispose_bag:add(state.AutoPullMode:on_state_change():addAction(function(_, new_value)
        if new_value ~= 'Off' then
            local assist_target = self:get_party():get_assist_target()
            if assist_target:get_id() ~= windower.ffxi.get_player().id then
                self:get_party():add_to_chat(self:get_party():get_player(), "I can't pull while I'm assisting someone else, so I'm going to stop assisting "..assist_target:get_name()..".")
                self:get_party():set_assist_target(self:get_party():get_player())
            end
        end
    end), state.AutoPullMode:on_state_change())

    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(_, _, _, _, message_id, param1, _, _)
        if state.AutoPullMode.value ~= 'Off' then
            -- Out of range
            if L{4, 5}:contains(message_id) then
                self.out_of_range_counter = self.out_of_range_counter + 1

                if self.out_of_range_counter > 3 then
                    windower.send_command('input /echo Target is out of range, disengaging.')
                    self.action_queue:clear()
                    self.action_queue:push_action(CommandAction.new(0, 0, 0, '/attack off'), true)

                    local target_action = TargetAction.new(windower.ffxi.get_player().id, self:get_player())
                    target_action.priority = ActionPriority.high
                    self.action_queue:push_action(target_action)
                end
            end
            -- Already claimed
            if L{12}:contains(message_id) then
                windower.send_command('input /echo Target is already claimed, disengaging.')
                --self.action_queue:clear()
                --self.action_queue:push_action(CommandAction.new(0, 0, 0, '/attack off'), true)
                return
            end
        end
    end), WindowerEvents.ActionMessage)
end

function Puller:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index
    self.out_of_range_counter = 0
end

function Puller:tic(_, _)
    if state.AutoPullMode.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'tic', 'target_index', self.target_index or "nil")

    if self.target_index then
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target and party_util.party_claimed(target.id) then
            logger.notice(self.__class, 'tic', 'target_index', self.target_index, 'already claimed')
            return
        end
    end

    self:check_pull()
    self:check_target()
end

function Puller:check_pull()
    if os.time() - self.last_pull_time < 7 or (state.AutoTrustsMode.value ~= 'Off' and party_util.is_party_leader(windower.ffxi.get_player().id) and self:get_party():num_party_members() < 6)
            or L{'Target', 'Party'}:contains(state.AutoPullMode.value) then
        return
    end
    self.last_pull_time = os.time()

    if state.AutoPullMode.value ~= 'Off' then
        logger.notice(self.__class, 'check_pull', state.AutoPullMode.value)
        if self:should_pull() then
            local target = self:get_pull_target()
            self:pull_target(target)
        end
    end
end

function Puller:check_target()
    if os.time() - self.last_target_check_time < 2 or not L{'Target', 'Party'}:contains(state.AutoPullMode.value) then
        return
    end

    logger.notice(self.__class, 'check_target', state.AutoPullMode.value)

    local target = windower.ffxi.get_mob_by_target('t')
    if target then
        self.last_target_check_time = os.time()
        if state.AutoPullMode.value == 'Party' then
            local is_party_target = self:get_party():get_targets(function(t)
                return t:get_distance():sqrt() < 15 and t:get_mob().status == 1
            end):firstWhere(function(t)
                return t and t:get_mob().index == target.index
            end) ~= nil

            if not is_party_target then
                logger.notice(self.__class, 'check_target', target.name, res.statuses[target.status].en, target.distance:sqrt(), 'is not a party targeted mob')
                return
            end
        end
        if not party_util.party_claimed(target.id) or target.distance:sqrt() > 3 then
            self:pull_target(target)
        end
    end
end

function Puller:should_pull()
    if player.status == 'Idle' or self.target_index == nil
            and (party_util.get_mobs_targeting_party():length() > 0 or party_util.get_party_claimed_mobs():length() > 0) then
        return true
    end
    return false
end

function Puller:get_pull_target()
    logger.notice(self.__class, 'check_pull', 'get_pull_target', state.AutoPullMode.value)

    if state.AutoPullMode.value == 'Multi' then
        local player_id = windower.ffxi.get_player().id
        local current_targets = party_util.get_party_claimed_mobs():filter(function(mob_index)
            local mob = windower.ffxi.get_mob_by_index(mob_index)
            return mob.claim_id == player_id
        end)
        if current_targets and #current_targets > 0 then
            local mob = windower.ffxi.get_mob_by_index(current_targets[1])
            logger.notice(self.__class, 'get_pull_target', 'returning claimed mob', mob.name, mob.index)
            return mob
        end
        local auto_target_mob = ffxi_util.find_closest_mob(self.target_names, party_util.party_targets(windower.ffxi.get_player().id))
        if auto_target_mob then
            return auto_target_mob
        else
            local party_claimed_mob = ffxi_util.find_closest_mob(L{}, L{})
            if party_claimed_mob then
                return party_claimed_mob
            else
               return nil
            end
        end
    else
        local player_target = ffxi_util.mob_for_index(windower.ffxi.get_player().target_index)
        local current_targets = --[[party_util.get_party_claimed_mobs()]]self:get_party().target_tracker:get_targets():map(function(t) return t:get_mob().index  end):filter(function(index)
            local m = windower.ffxi.get_mob_by_index(index)
            return m and not self.blacklist:contains(m.name)
        end)
        if current_targets and #current_targets > 0 then
            --print('already have target 0')
            return windower.ffxi.get_mob_by_index(current_targets[1])
        elseif player_target and battle_util.is_valid_monster_target(player_target.id)
                and monster_util.is_unclaimed(player_target.id)
                and player_target.distance:sqrt() < self:get_pull_distance() then
            --print('already have target 2')
            return player_target
        else
            if state.AutoPullMode.value == 'All' then
                return ffxi_util.find_closest_mob(L{}, L{}, self.blacklist)
            else
                return ffxi_util.find_closest_mob(self.target_names)
            end
        end
    end
end

function Puller:get_pull_distance()
    if state.ApproachPullMode == "Auto" then
        return 15
    elseif self.pull_settings.Spells:length() > 0 then
        return 18
    elseif self.ranged_attack then
        return 22
    elseif self.approach then
        return 30
    else
        return 17
    end
end

function Puller:get_pull_action(target_index)
    local actions = L{}

    local current_target = player_util.get_current_target()
    if current_target and current_target.index ~= target_index then
        logger.notice(self.__class, 'get_pull_action', 'target mismatch')
        actions:append(KeyAction.new(0, 0, 0, 'escape'))
    end

    if self.approach or state.ApproachPullMode.value == "Auto" then
        actions:append(RunToAction.new(target_index, 3, true))
        actions:append(BlockAction.new(function() battle_util.target_mob(target_index) end))
    elseif self.pull_settings.Spells:length() > 0 then
        local spell = self.pull_settings.Spells:firstWhere(function(spell)
            return spell_util.can_cast_spell(spell:get_spell().id)
        end)
        if spell then
            actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self:get_player()))
        else
            return nil
        end
    elseif self.pull_settings.JobAbilities:length() > 0 then
        local job_ability = self.pull_settings.JobAbilities:firstWhere(function(job_ability)
            return job_util.can_use_job_ability(job_ability:get_name())
        end)
        if job_ability then
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability:get_name(), target_index))
        else
            return nil
        end
    elseif self.ranged_attack then
        local target = windower.ffxi.get_mob_by_index(target_index)
        actions:append(CommandAction.new(0, 0, 0, '/ra '..target.id))
    else
        return nil
    end

    local pull_action = SequenceAction.new(actions, 'pull_action')
    pull_action.priority = ActionPriority.highest

    return pull_action
end

function Puller:pull_target(target)
    if target ~= nil and target.distance:sqrt() < self:get_pull_distance() then
        logger.notice(self.__class, 'pull_target', target.name)
        self.no_pull_counter = 0
        local pull_action = self:get_pull_action(target.index)
        if pull_action then
            logger.notice(self.__class, 'pull_target', target.name, pull_action:tostring())

            local actions = L{}

            local current_target = player_util.get_current_target()
            if current_target and current_target.index ~= target.index then
                logger.notice(self.__class, 'pull_target', 'target mismatch', current_target.name, target.name)
                actions:append(KeyAction.new(0, 0, 0, 'escape'))
            end
            actions:append(TargetAction.new(target.id, self:get_player()))
            actions:append(WaitAction.new(0, 0, 0, 2))

            if pull_action:can_perform() then
                actions:append(pull_action)
            else
                logger.notice(self.__class, 'pull_target', 'pull action on cooldown')
            end
            local sequence_action = SequenceAction.new(actions, 'puller_target_' .. target.index)
            sequence_action.priority = ActionPriority.high
            sequence_action.display_name = "Pulling → "..target.name
            self.action_queue:push_action(sequence_action, true)
        else
            self:get_party():add_to_chat(self.party:get_player(), "I can't use any of my pull actions right now. Maybe we should try different ones?", "pull_action_cooldown", 10)
        end
    else
        self.no_pull_counter = self.no_pull_counter + 1
        if self.no_pull_counter == 4 then
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't find anything to pull. I'll check again soon.")
        elseif self.no_pull_counter == 8 then
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Hmm...I still can't find anything. Should we pick different monsters to fight?")
        end
    end
end

function Puller:get_pull_settings()
    return self.pull_settings
end

function Puller:set_pull_settings(pull_settings)
    self.pull_settings = pull_settings
end

function Puller:set_blacklist(blacklist)
    self.blacklist = blacklist
end

function Puller:get_blacklist()
    return self.blacklist
end

function Puller:get_type()
    return "puller"
end

function Puller:allows_duplicates()
    return false
end

function Puller:set_target_names(target_names)
    self.target_names = target_names
end

return Puller
