local WeaponSkiller = require('cylibs/trust/roles/weapon_skiller')
local Spammer = setmetatable({}, {__index = WeaponSkiller })
Spammer.__index = Spammer
Spammer.__class = "Spammer"

state.AutoSkillchainMode:set_description('Spam', "Okay, I'll use the same weapon skill as soon as I get TP.")

function Spammer.new(action_queue, weapon_skill_settings)
    local self = setmetatable(WeaponSkiller.new(action_queue, weapon_skill_settings, 'Spam'), Spammer)
    self.conditions = L{}
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
    for ability in self.abilities:filter(function(a) return not a:is_aoe() end):it() do
        all_abilities:append(ability)
    end

    local ability = all_abilities:extend(default_abilities):lastWhere(function(a)
        local all_conditions = L{}:extend(self.conditions):extend(a:get_conditions())
        return Condition.check_conditions(all_conditions, self:get_party():get_player():get_mob().index)
    end)
    if ability then
        return ability
    end
    return nil
end

function Spammer:get_delay()
    return 0.25
end

function Spammer:set_conditions(conditions)
    self.conditions = conditions
end

return Spammer