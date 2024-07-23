---------------------------
-- Condition checking whether the target's melee accuracy is above a given threshold.
-- @class module
-- @name MeleeAccuracyCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MeleeAccuracyCondition = setmetatable({}, { __index = Condition })
MeleeAccuracyCondition.__index = MeleeAccuracyCondition
MeleeAccuracyCondition.__type = "MeleeAccuracyCondition"
MeleeAccuracyCondition.__class = "MeleeAccuracyCondition"

function MeleeAccuracyCondition.new(accuracy_percentage, operator)
    local self = setmetatable(Condition.new(), MeleeAccuracyCondition)
    self.accuracy_percentage = accuracy_percentage or 75
    self.operator = operator or Condition.Operator.LessThanOrEqualTo
    return self
end

function MeleeAccuracyCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            print('accuracy is', party_member:get_battle_stat_tracker():get_accuracy())
            return Condition:eval(party_member:get_battle_stat_tracker():get_accuracy(), self.accuracy_percentage, self.operator)
        end
    end
    return false
end

function MeleeAccuracyCondition:get_config_items()
    return L{
        ConfigItem.new('accuracy_percentage', 1, 100, 1, function(value) return value.." %" end, "Accuracy"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function MeleeAccuracyCondition:tostring()
    return "Accuracy "..self.operator.." "..self.accuracy_percentage.. "%"
end

function MeleeAccuracyCondition.description()
    return "Melee accuracy."
end

function MeleeAccuracyCondition:serialize()
    return "MeleeAccuracyCondition.new(" .. serializer_util.serialize_args(self.accuracy_percentage, self.operator) .. ")"
end

function MeleeAccuracyCondition:__eq(otherItem)
    return otherItem.__class == MeleeAccuracyCondition.__class
        and otherItem.accuracy_percentage == self.accuracy_percentage
        and otherItem.operator == self.operator
end

return MeleeAccuracyCondition




