local Shooter = setmetatable({}, {__index = Role })
Shooter.__index = Shooter

state.AutoShootMode = M{['description'] = 'Auto Shoot Mode', 'Off', 'Auto', 'Manual'}
-- state.AutoShootMode:set_description('Auto', "Okay, so anyway I'll just start blasting 'em.") -- https://knowyourmeme.com/memes/so-anyway-i-started-blasting
state.AutoShootMode:set_description('Auto', "Okay, I'll automatically shoot at the enemy.")
state.AutoShootMode:set_description('Manual', "Okay, I'll keep shooting once started until I've got TP.")

function Shooter.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Shooter)

    self.last_shot = os.clock()

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
                self.last_shot = os.clock()
                if state.AutoShootMode.value == 'Auto' or state.AutoShootMode == 'Manual' then
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
        CommandAction.new(0, 0, 0, '/ra '..target.id),
        WaitAction.new(0, 0, 0, 1.5),
    }
    self.action_queue:push_action(SequenceAction.new(actions, 'ranged_attack'), true)
end

function Shooter:target_change(target_index)
    Role.target_change(self, target_index)
end

function Shooter:tic(_, _)
    if self.target_index == nil then return end

    if state.AutoShootMode.value == 'Auto' and os.clock() - self.last_shot > 1.5 then
        if windower.ffxi.get_player().vitals.tp < 1000 then
            local target = windower.ffxi.get_mob_by_index(self.target_index)
            if party_util.party_claimed(target.id) then
                self:ranged_attack(target)
            end
        end
    end

end

function Shooter:allows_duplicates()
    return false
end

function Shooter:get_type()
    return "shooter"
end

return Shooter