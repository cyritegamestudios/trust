---------------------------
-- Condition checking whether the target is valid.
-- @class module
-- @name ValidTargetCondition

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

return ValidTargetCondition




