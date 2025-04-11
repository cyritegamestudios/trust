---------------------------
-- Condition checking a logical expression.
-- @class module
-- @name ConditionalCondition
local localization_util = require('cylibs/util/localization_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ConditionalCondition = setmetatable({}, { __index = Condition })
ConditionalCondition.__index = ConditionalCondition
ConditionalCondition.__type = "ConditionalCondition"
ConditionalCondition.__class = "ConditionalCondition"

function ConditionalCondition.new(conditions, operator, target_index)
    local self = setmetatable(Condition.new(target_index), ConditionalCondition)
    self.conditions = conditions or L{}
    self.operator = operator or Condition.LogicalOperator.And
    return self
end

function ConditionalCondition:is_satisfied(target_index)
    local satisfied = false
    if self.operator == Condition.LogicalOperator.Or then
        satisfied = false
    elseif self.operator == Condition.LogicalOperator.And then
        satisfied = true
    end
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        for condition in self.conditions:it() do
            local result = condition:is_satisfied(target_index)
            if self.operator == Condition.LogicalOperator.Or then
                satisfied = satisfied or result
            elseif self.operator == Condition.LogicalOperator.And then
                satisfied = satisfied and result
            end
        end
    end
    return satisfied
end

function ConditionalCondition:tostring()
    return localization_util.commas(self.conditions:map(function(condition) return condition:tostring() end), self.operator)
end

function ConditionalCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function ConditionalCondition:serialize()
    return "ConditionalCondition.new(" .. serializer_util.serialize_args(self.conditions, self.operator) .. ")"
end

return ConditionalCondition




