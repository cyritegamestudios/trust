local CombatMode = setmetatable({}, {__index = Role })
CombatMode.__index = CombatMode

state.AutoFaceMobMode = M{['description'] = 'Auto Face Mob Mode', 'Auto', 'Off'}
state.CombatMode = M{['description'] = 'Combat Mode', 'Off', 'Melee', 'Ranged'}

function CombatMode.new(action_queue, melee_distance, range_distance)
    local self = setmetatable(Role.new(action_queue), CombatMode)
    self.action_queue = action_queue
    self.melee_distance = melee_distance
    self.range_distance = range_distance
    return self
end

function CombatMode:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index
end

function CombatMode:tic(new_time, old_time)
    if self.target_index == nil then return end

    self:check_distance()
end

function CombatMode:check_distance()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if target == nil or not battle_util.is_valid_target(target.id) then return end

    if L{'Ranged'}:contains(state.CombatMode.value) then
        if target.distance:sqrt() < self.range_distance then
            self.action_queue:push_action(RunAwayAction.new(target.index, self.range_distance), true)
        elseif target.distance:sqrt() > (self.range_distance + 0.5) then
            player_util.face(target)
            self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
            self.action_queue:push_action(RunToAction.new(target.index, self.range_distance), true)
        else
            self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
        end
    elseif L{'Melee'}:contains(state.CombatMode.value) then
        if target.distance:sqrt() > self.melee_distance then
            self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
            self.action_queue:push_action(RunToAction.new(target.index, self.melee_distance), true)
        else
            self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
        end
    else
        if state.AutoFaceMobMode.value ~= 'Off' then
            self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
        end
    end
end

function CombatMode:allows_duplicates()
    return false
end

function CombatMode:get_type()
    return "combatmode"
end

return CombatMode