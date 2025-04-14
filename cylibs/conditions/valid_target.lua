---------------------------
-- Condition checking whether the target is valid.
-- @class module
-- @name ValidTargetCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ValidTargetCondition = setmetatable({}, { __index = Condition })
ValidTargetCondition.__index = ValidTargetCondition
ValidTargetCondition.__class = "ValidTargetCondition"

function ValidTargetCondition.new(blacklist_names)
    local self = setmetatable(Condition.new(), ValidTargetCondition)
    self.blacklist_names = blacklist_names or S{}
    return self
end

function ValidTargetCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target == nil or self.blacklist_names:contains(target.name) or not target.valid_target then
        if target then
            logger.notice(self.__class, 'invalid_target', target.name, self.blacklist_names:contains(target.name), not target.valid_target)
        end
        return false
    end
    return true
end

function ValidTargetCondition:tostring()
    return "ValidTargetCondition"
end

function ValidTargetCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function ValidTargetCondition:serialize()
    return "ValidTargetCondition.new(" .. serializer_util.serialize_args(self.blacklist_names) .. ")"
end

return ValidTargetCondition




