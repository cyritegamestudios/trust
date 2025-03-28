local GambitCondition = require('cylibs/gambits/gambit_condition')
local GambitTarget = require('cylibs/gambits/gambit_target')
local localization_util = require('cylibs/util/localization_util')
local serializer_util = require('cylibs/util/serializer_util')

local Gambit = {}
Gambit.__index = Gambit
Gambit.__class = "Gambit"

Gambit.Tags = {}
Gambit.Tags.AllTags = L{
    'Buffs',
    'Debuffs',
    'Food',
    'Nukes',
}

function Gambit.new(target, conditions, ability, conditions_target, tags)
    local self = setmetatable({}, Gambit)
    self.target = target
    self.conditions = (conditions or L{}):map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, conditions_target)
        end
        return condition
    end)
    self.ability = ability
    self.conditions_target = conditions_target
    self.tags = tags or L{}
    self.enabled = true

    return self
end

function Gambit:isSatisfied(target_by_type, param)
    if self:getAbility() == nil then
        return false
    end

    local satisfied_conditions = self.conditions:filter(function(condition)
        local target = target_by_type(condition:getTargetType())
        return condition:isSatisfied(target, param)
    end)
    return satisfied_conditions:length() == self.conditions:length()
        and Condition.check_conditions(self:getAbility():get_conditions(), windower.ffxi.get_player().index, param)
end

function Gambit:getAbility()
    return self.ability
end

function Gambit:getAbilityTarget()
    return self.target
end

function Gambit:addCondition(condition)
    if condition.__type ~= GambitCondition.__type then
        condition = GambitCondition.new(condition, self:getConditionsTarget())
    end
    for c in self.conditions:it() do
        if c:getCondition() == condition:getCondition() then
            return
        end
    end
    self.conditions:append(condition)
end

function Gambit:getConditions()
    return self.conditions
end

function Gambit:getConditionsTarget()
    return self.conditions_target
end

function Gambit:hasConditionTarget(targetType)
    if targetType == self:getConditionsTarget() then
        return true
    end
    for condition in self.conditions:it() do
        if condition:getTargetType() == targetType then
            return true
        end
    end
    return false
end

function Gambit:addTag(tag)
    self.tags:append(tag)
end

function Gambit:getTags()
    return S(self.tags)
end

function Gambit:isReaction()
    return self:getTags():contains('reaction') or self:getTags():contains('Reaction')
end

function Gambit:setEnabled(enabled)
    self.enabled = enabled
end

function Gambit:isEnabled()
    return self.enabled
end

function Gambit:isValid()
    if not self:getAbility():is_valid() then
        return false
    end
    local job_conditions = self:getAbility():get_conditions():filter(function(condition)
        return condition.__class == MainJobCondition.__class
    end) or L{}
    return job_conditions:empty() or Condition.check_conditions(job_conditions, windower.ffxi.get_player().index)
end

function Gambit:getConditionsDescription()
    local conditions_by_type = {}
    for type in L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally, GambitTarget.TargetType.Enemy }:it() do
        conditions_by_type[type] = L{}
    end
    for condition in self:getConditions():it() do
        conditions_by_type[condition:getTargetType() or self:getConditionsTarget()]:append(condition)
    end
    local descriptions = L{}
    for type, conditions in pairs(conditions_by_type) do
        if conditions:length() > 0 then
            descriptions:append(string.format("%s: %s", type, localization_util.commas(conditions:map(function(c) return c:tostring() end))))
        end
    end
    return localization_util.commas(descriptions)
end

function Gambit:tostring()
    local conditionsDescription = "Never"
    if self.conditions:length() > 0 then
        conditionsDescription = self:getConditionsDescription()
    end
    local abilityName = self.ability:get_localized_name()
    if self.ability.get_display_name then
        abilityName = self.ability:get_display_name()
    end
    return string.format("%s → %s: %s", conditionsDescription, self.target, abilityName)
end

function Gambit:serialize()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return condition:should_serialize()
    end):unique()

    local tags = serializer_util.serialize(self.tags or L{}, 0)
    return "Gambit.new(" .. serializer_util.serialize(self.target) .. ", " .. serializer_util.serialize(conditions_to_serialize, 0) .. ", " .. self.ability:serialize(true) .. ", " .. serializer_util.serialize(self.conditions_target) .. ", " .. tags .. ")"
end

function Gambit:copy()
    local conditions = L{}
    for condition in self:getConditions():it() do
        conditions:append(condition:copy())
    end
    return Gambit.new(self:getAbilityTarget(), conditions, self:getAbility(), self:getConditionsTarget(), L(self:getTags()))
end

function Gambit:__eq(otherItem)
    return otherItem.__class == Gambit.__class
            and self:tostring() == otherItem:tostring()
end

return Gambit