---------------------------
-- Condition checking whether the target is valid.
-- @class module
-- @name ValidTargetCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ValidTargetCondition = setmetatable({}, { __index = Condition })
ValidTargetCondition.__index = ValidTargetCondition

function ValidTargetCondition.new(monster_target_only)
    local self = setmetatable(Condition.new(), ValidTargetCondition)
    self.monster_target_only = monster_target_only
    return self
end

function ValidTargetCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target == nil then
        return false
    end
    return true
end

function ValidTargetCondition:tostring()
    return "ValidTargetCondition"
end

function ValidTargetCondition:serialize()
    return "ValidTargetCondition.new(" .. serializer_util.serialize_args(self.monster_target_only) .. ")"
end

return ValidTargetCondition




