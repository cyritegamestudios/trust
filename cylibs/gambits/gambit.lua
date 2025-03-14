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
    self.conditions = conditions or L{}
    self.ability = ability
    self.conditions_target = conditions_target
    self.tags = tags or L{}
    self.enabled = true

    return self
end

function Gambit:isSatisfied(target, param)
    if target == nil or target:get_mob() == nil or self:getAbility() == nil then
        return false
    end
    return self.conditions:length() > 0 and Condition.check_conditions(self.conditions, target:get_mob().index, param)
        and Condition.check_conditions(self:getAbility():get_conditions(), windower.ffxi.get_player().index, param)
end

function Gambit:getAbility()
    return self.ability
end

function Gambit:getAbilityTarget()
    return self.target
end

function Gambit:addCondition(condition)
    if not self:getConditions():contains(condition) then
        self.conditions:append(condition)
    end
end

function Gambit:getConditions()
    return self.conditions
end

function Gambit:getConditionsTarget()
    return self.conditions_target
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

function Gambit:tostring()
    local conditionsDescription = "Never"
    if self.conditions:length() > 0 then
        conditionsDescription = localization_util.commas(self.conditions:map(function(condition) return condition:tostring()  end))
    end
    local abilityName = self.ability:get_localized_name()
    if self.ability.get_display_name then
        abilityName = self.ability:get_display_name()
    end
    return self.conditions_target..": "..conditionsDescription.. " → "..self.target..": "..abilityName
end

function Gambit:serialize()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return condition:should_serialize()
    end)
    local conditions = serializer_util.serialize(conditions_to_serialize, 0)
    local tags = serializer_util.serialize(self.tags or L{}, 0)
    return "Gambit.new(" .. serializer_util.serialize(self.target) .. ", " .. conditions .. ", " .. self.ability:serialize() .. ", " .. serializer_util.serialize(self.conditions_target) .. ", " .. tags .. ")"
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