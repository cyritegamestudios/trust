---------------------------
-- Condition checking whether an enemy has a cumulative magic effect.
-- @class module
-- @name HasCumulativeMagicEffectCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local Condition = require('cylibs/conditions/condition')
local HasCumulativeMagicEffectCondition = setmetatable({}, { __index = Condition })
HasCumulativeMagicEffectCondition.__index = HasCumulativeMagicEffectCondition
HasCumulativeMagicEffectCondition.__type = "HasCumulativeMagicEffectCondition"
HasCumulativeMagicEffectCondition.__class = "HasCumulativeMagicEffectCondition"

function HasCumulativeMagicEffectCondition.new(element_name, level, operator)
    local self = setmetatable(Condition.new(), HasCumulativeMagicEffectCondition)
    self.element_name = element_name or "Earth"
    self.level = level or 1
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function HasCumulativeMagicEffectCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local monster = player.alliance:get_target_by_index(target_index)
        if monster then
            local cumulative_effect = monster:get_cumulative_effect()
            if cumulative_effect and cumulative_effect:get_element() == self.element_name then
                return self:eval(cumulative_effect:get_level(), self.level, self.operator)
            end
        end
    end
    return false
end

function HasCumulativeMagicEffectCondition:get_config_items()
    local all_elements = L{
        "Fire",
        "Ice",
        "Wind",
        "Earth",
        "Lightning",
        "Water",
        "Light",
        "Dark"
    }

    return L{
        PickerConfigItem.new('element_name', self.element_name, all_elements, function(element_name)
            return i18n.resource('elements', 'en', element_name)
        end, "Element"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator"),
        ConfigItem.new('level', 1, 5, 1, nil, "Level")
    }
end

function HasCumulativeMagicEffectCondition:tostring()
    return "Cumulative Magic Effect: "..self.element_name..' '..self.operator..' lv.'..self.level
end

function HasCumulativeMagicEffectCondition.description()
    return "Has cumulative magic effect."
end

function HasCumulativeMagicEffectCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function HasCumulativeMagicEffectCondition:serialize()
    return "HasCumulativeMagicEffectCondition.new(" .. serializer_util.serialize_args(self.element_name, self.level, self.operator) .. ")"
end

return HasCumulativeMagicEffectCondition




