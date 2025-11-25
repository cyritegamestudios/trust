---------------------------
-- Condition checking whether the target is valid.
-- @class module
-- @name ValidTargetCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ValidTargetCondition = setmetatable({}, { __index = Condition })
ValidTargetCondition.__index = ValidTargetCondition
ValidTargetCondition.__class = "ValidTargetCondition"

ValidTargetCondition.EntityType = {}
ValidTargetCondition.EntityType.All = "All"
ValidTargetCondition.EntityType.Monster = "Monster"

function ValidTargetCondition.new(blacklist_names, entity_type)
    local self = setmetatable(Condition.new(), ValidTargetCondition)
    self.blacklist_names = blacklist_names or S{}
    self.entity_type = entity_type or ValidTargetCondition.EntityType.All
    return self
end

function ValidTargetCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target == nil or self.blacklist_names:contains(target.name) or not target.valid_target
            or not self:check_entity_type(target) then
        if target then
            logger.notice(self.__class, 'invalid_target', target.name, self.blacklist_names:contains(target.name), not target.valid_target)
        end
        return false
    end
    return true
end

function ValidTargetCondition:check_entity_type(target)
    if target == nil then
        return false
    end
    if self.entity_type == ValidTargetCondition.EntityType.Monster then
        return target.spawn_type == 16
    end
    return true
end

function ValidTargetCondition:tostring()
    return "Is a valid target"
end

function ValidTargetCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function ValidTargetCondition:serialize()
    return "ValidTargetCondition.new(" .. serializer_util.serialize_args(self.blacklist_names, self.entity_type) .. ")"
end

return ValidTargetCondition




