---------------------------
-- Condition checking the target's distance.
-- @class module
-- @name DistanceCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local DistanceCondition = setmetatable({}, { __index = Condition })
DistanceCondition.__index = DistanceCondition
DistanceCondition.__type = "DistanceCondition"
DistanceCondition.__class = "DistanceCondition"

function DistanceCondition.new(distance, operator)
    local self = setmetatable(Condition.new(), DistanceCondition)
    self.distance = distance or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function DistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return self:eval(target.distance:sqrt(), self.distance, self.operator)
    end
    return false
end

function DistanceCondition:get_config_items()
    return L{
        ConfigItem.new('distance', 0, 50, 1, function(value) return value.." yalms" end, "Distance"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function DistanceCondition:tostring()
    return "Distance "..self.operator.." "..self.distance.." yalms."
end

function DistanceCondition.valid_targets()
    return S{ Condition.TargetType.Enemy, Condition.TargetType.Ally }
end

function DistanceCondition:serialize()
    return "DistanceCondition.new(" .. serializer_util.serialize_args(self.distance, self.operator) .. ")"
end

function DistanceCondition.description()
    return "Distance."
end

function DistanceCondition:__eq(otherItem)
    return otherItem.__class == DistanceCondition.__class
            and self.distance == otherItem.distance
            and self.operator == otherItem.operator
end

return DistanceCondition




