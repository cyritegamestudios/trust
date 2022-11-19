local monster_util = require('cylibs/util/monster_util')
local TargetAction = require('cylibs/actions/target')

local Puller = setmetatable({}, {__index = Role })
Puller.__index = Puller

state.AutoPullMode = M{['description'] = 'Auto Pull Mode', 'Off', 'Auto','Multi'}

function Puller.new(action_queue, target_names, spell_name, job_ability_name)
    local self = setmetatable(Role.new(action_queue), Puller)

    self.action_queue = action_queue
    self.action_events = {}
    self.target_names = target_names
    self.spell_name = spell_name
    self.job_ability_name = job_ability_name
    self.out_of_range_counter = 0
    self.last_pull_time = os.time()

    return self
end

function Puller:destroy()
    Role.destroy(self)

    for _,event in pairs(self.action_events) do
        windower.unregister_event(event)
    end
    self.action_events = nil
end

function Puller:on_add()
    self.action_events.message = windower.register_event('action message', function(_, _, _, _, message_id, param1, _, _)
        if state.AutoPullMode.value ~= 'Off' then
            -- Out of range
            if L{4, 5}:contains(message_id) then
                self.out_of_range_counter = self.out_of_range_counter + 1

                if self.out_of_range_counter > 3 then
                    windower.send_command('input /echo Target is out of range, disengaging.')
                    self.action_queue:clear()
                    self.action_queue:push_action(CommandAction.new(0, 0, 0, '/attack off'), true)
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
    end)
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

    if self.target_index then
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target and battle_util.is_valid_target(target.id) then
            if windower.ffxi.get_player().target_index ~= target.index then
                print('already have target 1')
                local target_action = TargetAction.new(target.id, self:get_player())
                target_action.priority = ActionPriority.high
                self.action_queue:push_action(target_action)
            end
            return
        end
    end

    self:check_pull()
end

function Puller:check_pull()
    if os.time() - self.last_pull_time < 7 or (state.AutoTrustsMode.value ~= 'Off' and self:get_party():num_party_members() < 6) then
        return
    end
    self.last_pull_time = os.time()

    if state.AutoPullMode.value ~= 'Off' then
        if player.status == 'Idle' then
            local target = self:get_pull_target()
            if target ~= nil and target.distance:sqrt() < self:get_pull_distance() then
                local pull_action = self:get_pull_action(target.index)
                if pull_action:can_perform() then
                    local sequence_action = SequenceAction.new(L{
                        TargetAction.new(target.id, self:get_player()),
                        WaitAction.new(0, 0, 0, 2),
                        pull_action,
                    }, 'puller_target_' .. target.index)
                    sequence_action.priority = ActionPriority.high
                    self.action_queue:push_action(sequence_action, true)
                end
            end
        end
    end
end

function Puller:get_pull_target()
    if state.AutoPullMode.value == 'Multi' then
        local auto_target_mob = ffxi_util.find_closest_mob(L{}, party_util.party_targets())
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
        local current_targets = party_util.get_party_claimed_mobs()
        if current_targets and #current_targets > 0 then
            --print('already have target 0')
            return windower.ffxi.get_mob_by_index(current_targets[1])
        elseif battle_util.is_valid_monster_target(ffxi_util.mob_id_for_index(windower.ffxi.get_player().target_index))
                and monster_util.is_unclaimed(ffxi_util.mob_id_for_index(windower.ffxi.get_player().target_index)) then
            --print('already have target 2')
            return windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index)
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
    if self.spell_name then
        local pull_action = SpellAction.new(0, 0, 0, res.spells:with('en', self.spell_name).id, target_index, self:get_player())
        pull_action.priority = ActionPriority.highest
        return pull_action
    elseif self.job_ability_name then
        local pull_action = JobAbilityAction.new(0, 0, 0, self.job_ability_name, target_index)
        pull_action.priority = ActionPriority.highest
        return pull_action
    end
    return nil
end

function Puller:get_type()
    return "puller"
end

return Puller