local WeaponSkiller = require('cylibs/trust/roles/weapon_skiller')
local Spammer = setmetatable({}, {__index = WeaponSkiller })
Spammer.__index = Spammer
Spammer.__class = "Spammer"

state.AutoSkillchainMode:set_description('Spam', "Okay, I'll use the same weapon skill as soon as I get TP.")

function Spammer.new(action_queue, weapon_skill_settings)
    local self = setmetatable(WeaponSkiller.new(action_queue, weapon_skill_settings, 'Spam'), Spammer)
    return self
end

function Spammer:get_type()
    return "spammer"
end

function Spammer:get_next_ability()
    local default_abilities = L{}

    for skill in self.active_skills:it() do
        local default_ability = skill:get_default_ability()
        if default_ability then
            default_abilities:append(default_ability)
        end
    end

    local all_abilities = L{}
    for ability in self.abilities:it() do
        all_abilities:append(ability)
    end

    local ability = all_abilities:extend(default_abilities):lastWhere(function(a)
        return Condition.check_conditions(a:get_conditions(), self:get_party():get_player():get_mob().index)
    end)
    if ability then
        return ability
    end
    return nil
end

return Spammer