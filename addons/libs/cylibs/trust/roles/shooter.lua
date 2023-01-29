local Shooter = setmetatable({}, {__index = Role })
Shooter.__index = Shooter

state.AutoShootMode = M{['description'] = 'Auto Shoot Mode', 'Off', 'Auto'}
state.AutoShootMode:set_description('Auto', "Okay, I'll start shooting again after I weapon skill.")

function Shooter.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Shooter)

    self.action_events = {}

    return self
end

function Shooter:destroy()
    Role.destroy(self)
end

function Shooter:on_add()
    Role.on_add(self)

    self:get_player():on_ranged_attack_end():addAction(
            function (_, target)
                if state.AutoShootMode.value == 'Auto' then
                    if windower.ffxi.get_player().vitals.tp < 1000 then
                        self:ranged_attack(target)
                    end
                end
            end)

    self:get_player():on_weapon_skill_finish():addAction(
            function (_, target)
                if state.AutoShootMode.value == 'Auto' then
                    if windower.ffxi.get_player().vitals.tp < 1000 then
                        self:ranged_attack(target)
                    end
                end
            end)
end

function Shooter:ranged_attack(target)
    local actions = L{
        WaitAction.new(0, 0, 0, 3),
        CommandAction.new(0, 0, 0, '/ra '..target.id)
    }
    self.action_queue:push_action(SequenceAction.new(actions, 'ranged_attack'), true)
end

function Shooter:target_change(target_index)
    Role.target_change(self, target_index)
end

function Shooter:tic(_, _)
    if self.target_index == nil then return end
end

function Shooter:allows_duplicates()
    return false
end

function Shooter:get_type()
    return "shooter"
end

return Shooter