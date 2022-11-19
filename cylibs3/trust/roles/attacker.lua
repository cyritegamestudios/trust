local Attacker = setmetatable({}, {__index = Role })
Attacker.__index = Attacker

function Attacker.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Attacker)
    self.action_queue = action_queue
    return self
end

function Attacker:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index
end

function Attacker:tic(new_time, old_time)
    Role.tic(self, new_time, old_time)

    if self.target_index == nil then
        return
    end

    self:check_engage()
end

function Attacker:check_engage()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if target == nil or not battle_util.is_valid_target(target.id) then
        return
    end

    if player.status == 'Idle' then
        if state.AutoEngageMode.value == 'Always' then
            local attack_action = BlockAction.new(function() battle_util.target_mob(target.index) end)
            attack_action.priority = ActionPriority.high
            self.action_queue:push_action(attack_action)
            --local actions = L{
            --    WaitAction.new(0, 0, 0, 1),
            --    EngageAction.new(target.id, 324, nil, false) -- TODO: (scretella) change approach back to false
            --}
            -- The sequence action is causing Trust stack to go negative every time MNK/WAR assists engages
            -- Maybe I don't need this? Combat mode can take care of the approach logic
            -- It also repros with EngageAction only
            --self.action_queue:push_action(SequenceAction.new(actions, target.id), true)
        elseif state.AutoEngageMode.value == 'Assist' then
            if player.assist_target then
                self.action_queue:push_action(CommandAction.new(0, 0, 0, '/assist '..player.assist_target:get_name()), true)
            end
        end
    end
end

function Attacker:allows_duplicates()
    return false
end

function Attacker:get_type()
    return "attacker"
end

return Attacker