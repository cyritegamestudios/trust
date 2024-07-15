local localization_util = require('cylibs/util/localization_util')
local serializer_util = require('cylibs/util/serializer_util')

local Gambit = {}
Gambit.__index = Gambit
Gambit.__class = "Gambit"

function Gambit.new(target, conditions, ability)
    local self = setmetatable({}, Gambit)

    self.target = target
    self.conditions = conditions
    self.ability = ability

    return self
end

function Gambit:isSatisfied(target)
    local allConditions = L{}:extend(self.conditions):extend(self:getAbility():get_conditions())
    return self.conditions:length() > 0 and Condition.check_conditions(allConditions, target:get_mob().index)
end

function Gambit:getAbility()
    return self.ability
end

function Gambit:tostring()
    local conditionsDescription = "Never"
    if self.conditions:length() > 0 then
        conditionsDescription = localization_util.commas(self.conditions:map(function(condition) return condition:tostring()  end))
    end
    return self.target..": "..conditionsDescription.. " → "..self.ability:get_name()
end

function Gambit:serialize()
    --return "Gambit.new(" .. serializer_util.serialize_args(self.target, self.conditions, self.ability).. ")"
    local conditions = serializer_util.serialize(self.conditions, 0)
    return "Gambit.new(" .. serializer_util.serialize(self.target) .. ", " .. conditions .. ", " .. self.ability:serialize() .. ")"
end

return Gambit