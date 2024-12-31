---------------------------
-- Condition checking whether a list of conditions all return `false`.
-- @class module
-- @name NotCondition
local localization_util = require('cylibs/util/localization_util')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local NotCondition = setmetatable({}, { __index = Condition })
NotCondition.__index = NotCondition
NotCondition.__type = "NotCondition"
NotCondition.__class = "NotCondition"

function NotCondition.new(conditions, target_index)
    local self = setmetatable(Condition.new(target_index), NotCondition)
    self.conditions = conditions or L{}
    return self
end

function NotCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        for condition in self.conditions:it() do
            if condition:is_satisfied(target_index) then
                return false
            end
        end
    end
    return true
end

function NotCondition:get_config_items()
    if self.conditions:length() > 0 then
        return self.conditions[1]:get_config_items()
    end
    return nil
end

function NotCondition:tostring()
    return "Not "..localization_util.commas(self.conditions:map(function(condition) return condition:tostring() end))
end

function NotCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function NotCondition:serialize()
    return "NotCondition.new(" .. serializer_util.serialize_args(self.conditions) .. ")"
end

function NotCondition:should_serialize()
    for condition in self.conditions:it() do
        if not condition:should_serialize() then
            return false
        end
    end
    return Condition.should_serialize(self)
end

function NotCondition:__eq(otherItem)
    if otherItem.__class ~= NotCondition.__class then
        return false
    end
    local otherConditions = otherItem.conditions
    for condition in self.conditions:it() do
        if not otherConditions:contains(condition) then
            return false
        end
    end
    return true
end

return NotCondition




