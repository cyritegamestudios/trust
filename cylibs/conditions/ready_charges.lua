---------------------------
-- Condition checking whether the player has the specified number of ready charges.
-- @class module
-- @name ReadyChargesCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local ReadyChargesCondition = setmetatable({}, { __index = Condition })
ReadyChargesCondition.__index = ReadyChargesCondition
ReadyChargesCondition.__type = "ReadyChargesCondition"
ReadyChargesCondition.__class = "ReadyChargesCondition"

function ReadyChargesCondition.new(ready_charges, operator)
    local self = setmetatable(Condition.new(), ReadyChargesCondition)
    self.ready_charges = ready_charges or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function ReadyChargesCondition:is_satisfied(target_index)
    return self:eval(player_util.get_ready_charges(), self.ready_charges, self.operator)
end

function ReadyChargesCondition:get_config_items()
    return L{
        ConfigItem.new('ready_charges', 0, 3, 1, function(value) return value.."" end, "Number of Ready Charges"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function ReadyChargesCondition:tostring()
    return "Ready charges "..self.operator.." "..self.ready_charges
end

function ReadyChargesCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function ReadyChargesCondition:serialize()
    return "ReadyChargesCondition.new(" .. serializer_util.serialize_args(self.ready_charges, self.operator) .. ")"
end

function ReadyChargesCondition:tostring()
    return "Has "..' '..self.operator..' '..self.ready_charges..' ready charges'
end

function ReadyChargesCondition.description()
    return "Has ready charges."
end

function ReadyChargesCondition:__eq(otherItem)
    return otherItem.__class == ReadyChargesCondition.__class
            and self.ready_charges == otherItem.ready_charges
            and self.operator == otherItem.operator
end

return ReadyChargesCondition




