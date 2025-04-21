local serializer_util = require('cylibs/util/serializer_util')

local GambitGroup = {}
GambitGroup.__index = GambitGroup
GambitGroup.__type = "GambitGroup"
GambitGroup.__class = "GambitGroup"

function GambitGroup.new(gambits, conditions, description)
    local self = setmetatable({}, GambitGroup)

    self.gambits = gambits
    self.conditions = conditions
    self.description = description
    self.enabled = true

    return self
end

function GambitGroup:isSatisfied(target_by_type, param)
    local satisfied_conditions = self.conditions:filter(function(condition)
        local target = target_by_type(condition:getTargetType())
        return condition:isSatisfied(target, param)
    end)
    return satisfied_conditions:length() == self.conditions:length()
end

function GambitGroup:setEnabled(enabled)
    self.enabled = enabled
end

function GambitGroup:isEnabled()
    return self.enabled
end

function GambitGroup:isValid()
    for gambit in self.gambits:it() do
        if not gambit:isValid() then
            return false
        end
    end
    return true
end

function GambitGroup:tostring()
    return "GambitGroup"
    --[[local conditionsDescription = "Never"
    if self.conditions:length() > 0 then
        conditionsDescription = self:getConditionsDescription()
    end
    local abilityName = self.ability:get_localized_name()
    if self.ability.get_display_name then
        abilityName = self.ability:get_display_name()
    end
    return string.format("%s → %s: %s", conditionsDescription, self.target, abilityName)]]
end

function GambitGroup:serialize()
    return "GambitGroup.new(" .. serializer_util.serialize_args(self.gambits, self.conditions, self.description) .. ")"
end

return GambitGroup