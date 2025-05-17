---------------------------
-- Condition checking whether the skillchain is a specific step.
-- @class module
-- @name SkillchainStepCondition
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local SkillchainStepCondition = setmetatable({}, { __index = Condition })
SkillchainStepCondition.__index = SkillchainStepCondition
SkillchainStepCondition.__class = "SkillchainStepCondition"
SkillchainStepCondition.__type = "SkillchainStepCondition"

function SkillchainStepCondition.new(step_num, operator)
    local self = setmetatable(Condition.new(), SkillchainStepCondition)
    self.step_num = step_num or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function SkillchainStepCondition:is_satisfied(target_index)
    local party = player.party
    local player = player.party:get_player()
    if player then
        local enemy = party:get_target_by_index(player:get_target_index())
        if enemy then
            local step_num = 1
            local skillchain = enemy:get_skillchain()
            if skillchain then
                step_num = skillchain:get_step()
            end
            return self:eval(step_num, self.step_num, self.operator)
        end
    end
    return false
end

function SkillchainStepCondition:get_config_items()
    return L{
        ConfigItem.new('step_num', 0, 6, 1, function(value) return value.."" end, "Skillchain Step"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function SkillchainStepCondition:tostring()
    return "Skillchain step is "..self.operator.." "..self.step_num
end

function SkillchainStepCondition.description()
    return "Skillchain step."
end

function SkillchainStepCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy }
end

function SkillchainStepCondition:serialize()
    return "SkillchainStepCondition.new(" .. serializer_util.serialize_args(self.step_num, self.operator) .. ")"
end

function SkillchainStepCondition:__eq(otherItem)
    return otherItem.__class == SkillchainStepCondition.__class
            and self.step_num == otherItem.step_num
            and self.operator == otherItem.operator
end

return SkillchainStepCondition