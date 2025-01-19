---------------------------
-- Condition checking whether the skillchain window has a specified duration remaining.
-- @class module
-- @name SkillchainWindowCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local SkillchainWindowCondition = setmetatable({}, { __index = Condition })
SkillchainWindowCondition.__index = SkillchainWindowCondition
SkillchainWindowCondition.__class = "SkillchainWindowCondition"
SkillchainWindowCondition.__type = "SkillchainWindowCondition"

function SkillchainWindowCondition.new(duration, operator)
    local self = setmetatable(Condition.new(), SkillchainWindowCondition)
    self.duration = duration or 3
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function SkillchainWindowCondition:is_satisfied(target_index)
    local target = player.alliance:get_target_by_index(target_index) or player.alliance:get_target_by_index(player.party:get_player():get_target_index())
    if target and target:get_skillchain() then
        local skillchain = target:get_skillchain()
        if skillchain and not skillchain:is_expired() then
            local time_remaining_in_seconds = skillchain:get_time_remaining()
            return self:eval(time_remaining_in_seconds, self.duration, self.operator)
        end
    end
    return false
end

function SkillchainWindowCondition:get_config_items()
    return L{
        ConfigItem.new('duration', 0, 5, 0.5, function(value) return value.."s" end, "Time Remaining"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function SkillchainWindowCondition:tostring()
    return "Skillchain window has "..self.operator.." "..self.duration.."s remaining"
end

function SkillchainWindowCondition.description()
    return "Skillchain window."
end

function SkillchainWindowCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy }
end

function SkillchainWindowCondition:serialize()
    return "SkillchainWindowCondition.new(" .. serializer_util.serialize_args(self.duration, self.operator) .. ")"
end

function SkillchainWindowCondition:__eq(otherItem)
    return otherItem.__class == SkillchainWindowCondition.__class
            and self.duration == otherItem.duration
            and self.operator == otherItem.operator
end

return SkillchainWindowCondition