local Dispeler = setmetatable({}, {__index = Role })
Dispeler.__index = Dispeler

function Dispeler.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Dispeler)

    return self
end

function Dispeler:destroy()
    Role.destroy(self)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end
end

function Dispeler:on_add()
    Role.on_add(self)
end

function Dispeler:target_change(target_index)
    Role.target_change(self, target_index)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end

    if target_index then
        self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
        self.battle_target:monitor()
        self.battle_target:on_gain_buff():addAction(
                function (_, target_index, _)
                    self:dispel(target_index)
                end)
    end
end

function Dispeler:dispel(target_index)
    if state.AutoDispelMode.value == 'Off' then
        return
    end

    -- Spells
    local spell_names = job_util.get_dispel_spells(player.main_job_name_short, player.sub_job_name_short)
    for spell_name in spell_names:it() do
        local dispel = res.spells:with('en', spell_name)
        local dispel_action = SpellAction.new(0, 0, 0, dispel.id, target_index, self:get_player())
        dispel_action.priority = ActionPriority.high
        self.action_queue:push_action(dispel_action, true)
        return
    end

    -- Job abilities
    local job_ability_names = job_util.get_dispel_job_abilities(player.main_job_name_short, player.sub_job_name_short)
    for job_ability_name in job_ability_names:it() do
        if string.find(job_ability_name, 'Maneuver') then
            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability_name), true)
        else
            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability_name, target_index), true)
        end
        return
    end
end

function Dispeler:get_type()
    return "dispeler"
end

return Dispeler