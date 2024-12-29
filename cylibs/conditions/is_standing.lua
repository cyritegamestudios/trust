---------------------------
-- Condition checking whether the player is standing still.
-- @class module
-- @name IsStandingCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local IsStandingCondition = setmetatable({}, { __index = Condition })
IsStandingCondition.__index = IsStandingCondition
IsStandingCondition.__type = "IsStandingCondition"
IsStandingCondition.__class = "IsStandingCondition"

function IsStandingCondition.new(duration, operator)
    local self = setmetatable(Condition.new(), IsStandingCondition)
    self.duration = duration or 0
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function IsStandingCondition:is_satisfied(target_index)
    if player.player and not player.player:is_moving() then
        return self:eval(player.player:get_idle_duration(), self.duration, self.operator)
    end
    return false
end

function IsStandingCondition:get_config_items()
    return L{
        ConfigItem.new('duration', 0, 60, 1, function(value) return value.."s" end, "Time Not Moving"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function IsStandingCondition:tostring()
    return "Is not moving for "..self.operator.." "..self.duration.."s"
end

function IsStandingCondition.description()
    return "Is not moving."
end

function IsStandingCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function IsStandingCondition:serialize()
    return "IsStandingCondition.new(" .. serializer_util.serialize_args(self.duration, self.operator) .. ")"
end

return IsStandingCondition




