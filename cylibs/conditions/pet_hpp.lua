---------------------------
-- Condition checking the target's pet's hit points.
-- @class module
-- @name PetHitPointsPercentCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PetHitPointsPercentCondition = setmetatable({}, { __index = Condition })
PetHitPointsPercentCondition.__index = PetHitPointsPercentCondition
PetHitPointsPercentCondition.__type = "PetHitPointsPercentCondition"
PetHitPointsPercentCondition.__class = "PetHitPointsPercentCondition"

function PetHitPointsPercentCondition.new(hpp, operator)
    local self = setmetatable(Condition.new(), PetHitPointsPercentCondition)
    self.hpp = hpp or 25
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function PetHitPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local pet_index = target.pet_index
        if pet_index and pet_index ~= 0 then
            local pet = windower.ffxi.get_mob_by_index(pet_index)
            return Condition:eval(pet.hpp, self.hpp, self.operator)
        end
    end
    return false
end

function PetHitPointsPercentCondition:get_config_items()
    return L{
        ConfigItem.new('hpp', 0, 100, 1, function(value) return value.." %" end, "Pet HP %"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function PetHitPointsPercentCondition:tostring()
    return "Pet HP "..self.operator.." "..self.hpp.."%"
end

function PetHitPointsPercentCondition.description()
    return "Pet HP %."
end

function PetHitPointsPercentCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function PetHitPointsPercentCondition:serialize()
    return "PetHitPointsPercentCondition.new(" .. serializer_util.serialize_args(self.hpp, self.operator) .. ")"
end

return PetHitPointsPercentCondition




