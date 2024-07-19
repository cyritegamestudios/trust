local localization_util = require('cylibs/util/localization_util')
local serializer_util = require('cylibs/util/serializer_util')

local Gambit = {}
Gambit.__index = Gambit
Gambit.__class = "Gambit"

function Gambit.new(target, conditions, ability, conditions_target)
    local self = setmetatable({}, Gambit)

    self.target = target
    self.conditions = conditions or L{}
    self.ability = ability
    self.conditions_target = conditions_target

    return self
end

function Gambit:isSatisfied(target, param)
    local allConditions = L{}:extend(self.conditions):extend(self:getAbility():get_conditions())
    return self.conditions:length() > 0 and Condition.check_conditions(allConditions, target:get_mob().index, param)
end

function Gambit:getAbility()
    return self.ability
end

function Gambit:getAbilityTarget()
    return self.target
end

function Gambit:getConditions()
    return self.conditions
end

function Gambit:getConditionsTarget()
    return self.conditions_target
end

function Gambit:tostring()
    local conditionsDescription = "Never"
    if self.conditions:length() > 0 then
        conditionsDescription = localization_util.commas(self.conditions:map(function(condition) return condition:tostring()  end))
    end
    return self.conditions_target..": "..conditionsDescription.. " → "..self.target..": "..self.ability:get_name()
end

function Gambit:serialize()
    --return "Gambit.new(" .. serializer_util.serialize_args(self.target, self.conditions, self.ability).. ")"
    local conditions = serializer_util.serialize(self.conditions, 0)
    return "Gambit.new(" .. serializer_util.serialize(self.target) .. ", " .. conditions .. ", " .. self.ability:serialize() .. ", " .. serializer_util.serialize(self.conditions_target) .. ")"
end

function Gambit:copy()
    local conditions = L{}
    for condition in self:getConditions():it() do
        conditions:append(condition)
    end
    return Gambit.new(self:getAbilityTarget(), conditions, self:getAbility(), self:getConditionsTarget())
end

return Gambit