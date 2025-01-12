---------------------------
-- Condition checking whether the target's z distance <= distance.
-- @class module
-- @name MaxHeightDistanceCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MaxHeightDistanceCondition = setmetatable({}, { __index = Condition })
MaxHeightDistanceCondition.__index = MaxHeightDistanceCondition
MaxHeightDistanceCondition.__class = "MaxHeightDistanceCondition"
MaxHeightDistanceCondition.__type = "MaxHeightDistanceCondition"

function MaxHeightDistanceCondition.new(distance, operator, target_index)
    local self = setmetatable(Condition.new(target_index), MaxHeightDistanceCondition)
    self.distance = distance or 8
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function MaxHeightDistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target and windower.ffxi.get_player() then
        return self:eval(math.abs(windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).z - target.z), self.distance, self.operator)
    end
    return false
end

function MaxHeightDistanceCondition:get_config_items()
    return L{
        ConfigItem.new('distance', 0, 25, 1, function(value) return value.." yalms" end, "Target Elevation Distance"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function MaxHeightDistanceCondition:tostring()
    return "Target elevation distance "..self.operator.." "..self.distance.. " yalms"
end

function MaxHeightDistanceCondition.description()
    return "Target elevation distance from player."
end

function MaxHeightDistanceCondition.valid_targets()
    return S{ Condition.TargetType.Ally, Condition.TargetType.Enemy }
end

function MaxHeightDistanceCondition:serialize()
    return "MaxHeightDistanceCondition.new(" .. serializer_util.serialize_args(self.distance, self.operator) .. ")"
end

return MaxHeightDistanceCondition




