---------------------------
-- Condition checking the distance of a pet from a target.
-- @class module
-- @name PetDistanceCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PetDistanceCondition = setmetatable({}, { __index = Condition })
PetDistanceCondition.__index = PetDistanceCondition
PetDistanceCondition.__type = "PetDistanceCondition"
PetDistanceCondition.__class = "PetDistanceCondition"

function PetDistanceCondition.new(distance, operator)
    local self = setmetatable(Condition.new(), PetDistanceCondition)
    self.distance = distance or 21
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function PetDistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local pet = pet_util.get_pet()
        if pet then
            return self:eval(geometry_util.distance(target, pet), self.distance, self.operator)
        end
    end
    return false
end

function PetDistanceCondition:get_config_items()
    return L{
        ConfigItem.new('distance', 0, 21, 1, function(value) return value.." yalms" end, "Distance"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function PetDistanceCondition:tostring()
    return string.format("Pet distance %s %d yalms.", self.operator, self.distance)
end

function PetDistanceCondition.description()
    return "Pet distance."
end

function PetDistanceCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally, Condition.TargetType.Enemy }
end

function PetDistanceCondition:serialize()
    return "PetDistanceCondition.new(" .. serializer_util.serialize_args(self.distance, self.operator) .. ")"
end

return PetDistanceCondition




