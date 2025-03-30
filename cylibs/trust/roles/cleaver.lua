local WeaponSkiller = require('cylibs/trust/roles/weapon_skiller')
local Cleaver = setmetatable({}, {__index = WeaponSkiller })
Cleaver.__index = Cleaver
Cleaver.__class = "Cleaver"

state.AutoSkillchainMode:set_description('Cleave', "Cleave monsters with AOE weapon skills.")

function Cleaver.new(action_queue, weapon_skill_settings)
    local self = setmetatable(WeaponSkiller.new(action_queue, weapon_skill_settings, 'Cleave'), Cleaver)
    return self
end

function Cleaver:get_type()
    return "cleaver"
end

function Cleaver:get_next_ability()
    local ability = self.abilities:lastWhere(function(a)
        return a:is_aoe() and Condition.check_conditions(a:get_conditions(), self:get_party():get_player():get_mob().index)
    end)
    if ability then
        return ability
    end
    return nil
end

return Cleaver