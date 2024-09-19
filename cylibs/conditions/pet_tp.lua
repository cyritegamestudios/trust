---------------------------
-- Condition checking the player's pet's tactical points.
-- @class module
-- @name PetTacticalPointsCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PetTacticalPointsCondition = setmetatable({}, { __index = Condition })
PetTacticalPointsCondition.__index = PetTacticalPointsCondition
PetTacticalPointsCondition.__type = "PetTacticalPointsCondition"
PetTacticalPointsCondition.__class = "PetTacticalPointsCondition"

function PetTacticalPointsCondition.new(tp, operator)
    local self = setmetatable(Condition.new(), PetTacticalPointsCondition)
    self.tp = tp or 1000
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function PetTacticalPointsCondition:is_satisfied(target_index, tp)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target and tp then
        local pet_index = target.pet_index
        if pet_index and pet_index ~= 0 then
            local pet = windower.ffxi.get_mob_by_index(pet_index)
            return pet and Condition:eval(tp, self.tp, self.operator)
        end
    end
    return false
end

function PetTacticalPointsCondition:get_config_items()
    return L{
        ConfigItem.new('tp', 0, 3000, 100, function(value) return value.."" end, "TP"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function PetTacticalPointsCondition:tostring()
    return "Pet TP "..self.operator.." "..self.tp
end

function PetTacticalPointsCondition.description()
    return "Pet TP."
end

function PetTacticalPointsCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function PetTacticalPointsCondition:serialize()
    return "PetTacticalPointsCondition.new(" .. serializer_util.serialize_args(self.tp, self.operator) .. ")"
end

return PetTacticalPointsCondition




