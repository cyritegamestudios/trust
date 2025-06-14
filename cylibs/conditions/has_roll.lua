---------------------------
-- Condition checking whether the player has a roll.
-- @class module
-- @name HasRollCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local HasRollCondition = setmetatable({}, { __index = Condition })
HasRollCondition.__index = HasRollCondition
HasRollCondition.__type = "HasRollCondition"
HasRollCondition.__class = "HasRollCondition"

function HasRollCondition.new(roll_name, roll_num, operator)
    local self = setmetatable(Condition.new(), HasRollCondition)
    self.roll_name = roll_name
    self.roll_num = roll_num or 11
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function HasRollCondition:is_satisfied(_)
    for trust in L{ player.trust.main_job, player.trust.sub_job }:compact_map():it() do
        local roller = trust:role_with_type("roller")
        if roller then
            local roll_num = roller:get_roll_num(self.roll_name)
            if roll_num and self:eval(roll_num, self.roll_num, self.operator) then
                return true
            end
        end
    end
    return false
end

function HasRollCondition:get_config_items()
    return L{
        PickerConfigItem.new('roll_name', self.roll_name, res.job_abilities:with('type', 'CorsairRoll'):map(function(roll) return roll.en end), function(roll_name)
            return i18n.resource('job_abilities', 'en', roll_name)
        end, "Roll Name"),
        ConfigItem.new('roll_num', 0, 11, 1, function(value) return value.."" end, "Roll Number"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function HasRollCondition:tostring()
    return string.format("%s %s %d", self.roll_name, self.operator, self.roll_num)
end

function HasRollCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function HasRollCondition:serialize()
    return "HasRollCondition.new(" .. serializer_util.serialize_args(self.roll_name, self.roll_num, self.operator) .. ")"
end

function HasRollCondition.description()
    return "Has roll."
end

function HasRollCondition:__eq(otherItem)
    return otherItem.__class == HasRollCondition.__class
            and self.roll_name == otherItem.roll_name
            and self.roll_num == otherItem.roll_num
            and self.operator == otherItem.operator
end

return HasRollCondition




