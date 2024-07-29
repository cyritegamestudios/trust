local localization_util = require('cylibs/util/localization_util')
local serializer_util = require('cylibs/util/serializer_util')

local Gambit = {}
Gambit.__index = Gambit
Gambit.__class = "Gambit"

function Gambit.new(target, conditions, ability, conditions_target, tags)
    local self = setmetatable({}, Gambit)

    self.target = target
    self.conditions = conditions or L{}
    self.ability = ability
    self.conditions_target = conditions_target
    self.tags = tags or L{}
    self.enabled = true

    return self
end

function Gambit:isSatisfied(target, param)
    if target == nil or target:get_mob() == nil then
        return false
    end
    return self.conditions:length() > 0 and Condition.check_conditions(self.conditions, target:get_mob().index, param)
        and Condition.check_conditions(self:getAbility():get_conditions(), windower.ffxi.get_player().index, param)
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

function Gambit:addTag(tag)
    self.tags:append(tag)
end

function Gambit:getTags()
    return S(self.tags)
end

function Gambit:setEnabled(enabled)
    self.enabled = enabled
end

function Gambit:isEnabled()
    return self.enabled
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
    local tags = serializer_util.serialize(self.tags or L{}, 0)
    return "Gambit.new(" .. serializer_util.serialize(self.target) .. ", " .. conditions .. ", " .. self.ability:serialize() .. ", " .. serializer_util.serialize(self.conditions_target) .. ", " .. tags .. ")"
end

function Gambit:copy()
    local conditions = L{}
    for condition in self:getConditions():it() do
        conditions:append(condition:copy())
    end
    return Gambit.new(self:getAbilityTarget(), conditions, self:getAbility(), self:getConditionsTarget())
end

function Gambit:__eq(otherItem)
    return otherItem.__class == Gambit.__class
            and self:tostring() == otherItem:tostring()
end

return Gambit