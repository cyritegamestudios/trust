local CommandAction = require('cylibs/actions/command')
local DisposeBag = require('cylibs/events/dispose_bag')
local ffxi_util = require('cylibs/util/ffxi_util')
local monster_util = require('cylibs/util/monster_util')
local party_util = require('cylibs/util/party_util')
local TargetAction = require('cylibs/actions/target')

local Puller = setmetatable({}, {__index = Role })
Puller.__index = Puller

state.AutoPullMode = M{['description'] = 'Auto Pull Mode', 'Off', 'Auto','Multi','Target'}
state.AutoPullMode:set_description('Auto', "Okay, I'll automatically pull monsters for the party.")
state.AutoPullMode:set_description('Multi', "Okay, I'll pull my own monster even if we're already fighting.")
state.AutoPullMode:set_description('Target', "Okay, I'll pull whatever monster I'm currently targeting.")

function Puller.new(action_queue, target_names, spell_name, job_ability_name)
    return Puller.new(action_queue, target_names, spell_name, job_ability_name, false)
end

function Puller.new(action_queue, target_names, spell_name, job_ability_name, ranged_attack)
    local self = setmetatable(Role.new(action_queue), Puller)

    self.action_queue = action_queue
    self.action_events = {}
    self.target_names = target_names
    self.spell_name = spell_name
    self.job_ability_name = job_ability_name
    self.ranged_attack = ranged_attack
    self.approach = spell_name == nil and job_ability_name == nil and ranged_attack == false
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

    self.action_events = nil
end

function Puller:on_add()
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

    logger.notice("puller", "target is", target_index or "nil")

    if self.target_index then
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target and party_util.party_claimed(target.id) then
            return
        end
    end

    self:check_pull()
    self:check_target()
end

function Puller:check_pull()
    if os.time() - self.last_pull_time < 7 or (state.AutoTrustsMode.value ~= 'Off' and self:get_party():num_party_members() < 6)
            or state.AutoPullMode == 'Target' then
        return
    end
    self.last_pull_time = os.time()
    logger.notice("puller", "checking pull")
    if state.AutoPullMode.value ~= 'Off' then
        if self:should_pull() then
            logger.notice("puller", "trying to pull")
            local target = self:get_pull_target()
            self:pull_target(target)
        end
    end
end

function Puller:check_target()
    if os.time() - self.last_target_check_time < 2 or state.AutoPullMode.value ~= 'Target' then
        return
    end

    if player.status == 'Engaged' then
        local target = windower.ffxi.get_mob_by_target('t')
        if target and not party_util.party_claimed(target.id) then
            self:pull_target(target)
        end
        self.last_target_check_time = os.time()
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
    if state.AutoPullMode.value == 'Multi' then
        local auto_target_mob = ffxi_util.find_closest_mob(self.target_names, party_util.party_targets())
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
        local current_targets = party_util.get_party_claimed_mobs()
        if current_targets and #current_targets > 0 then
            --print('already have target 0')
            return windower.ffxi.get_mob_by_index(current_targets[1])
        elseif player_target and battle_util.is_valid_monster_target(player_target.id)
                and monster_util.is_unclaimed(player_target.id)
                and player_target.distance:sqrt() < self:get_pull_distance() then
            --print('already have target 2')
            return player_target
        else
            return ffxi_util.find_closest_mob(self.target_names)
        end
    end
end

function Puller:get_pull_distance()
    if self.spell_name then
        return 18
    else
        return 17
    end
end

function Puller:get_pull_action(target_index)
    if self.approach then
        local pull_action = SequenceAction.new(L{
            RunToAction.new(target_index, 3),
            BlockAction.new(function() battle_util.target_mob(target_index) end)
        }, "puller_approach", true)
        pull_action.priority = ActionPriority.highest
        return pull_action
    elseif self.spell_name then
        local pull_action = SpellAction.new(0, 0, 0, res.spells:with('en', self.spell_name).id, target_index, self:get_player())
        pull_action.priority = ActionPriority.highest
        return pull_action
    elseif self.job_ability_name then
        local pull_action = JobAbilityAction.new(0, 0, 0, self.job_ability_name, target_index)
        pull_action.priority = ActionPriority.highest
        return pull_action
    elseif self.ranged_attack then
        local target = windower.ffxi.get_mob_by_index(target_index)
        local pull_action = CommandAction.new(0, 0, 0, '/ra '..target.id)
        pull_action.priority = ActionPriority.highest
        return pull_action
    end
    return nil
end

function Puller:pull_target(target)
    if target ~= nil and target.distance:sqrt() < self:get_pull_distance() then
        logger.notice("found target to pull", target.name)
        self.no_pull_counter = 0
        local pull_action = self:get_pull_action(target.index)
        if pull_action then
            logger.notice("[Puller]", "Attempting to pull", target.name)
            local actions = L{
                TargetAction.new(target.id, self:get_player()),
                WaitAction.new(0, 0, 0, 2),
            }
            if pull_action:can_perform() then
                actions:append(pull_action)
            else
                logger.notice("[Puller]", "Can't use pull action so just targeting")
            end
            local sequence_action = SequenceAction.new(actions, 'puller_target_' .. target.index)
            sequence_action.priority = ActionPriority.high
            self.action_queue:push_action(sequence_action, true)
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