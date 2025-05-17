---------------------------
-- Condition checking whether <t> is a different mob than the trust target.
-- @class module
-- @name TargetMismatchCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local TargetMismatchCondition = setmetatable({}, { __index = Condition })
TargetMismatchCondition.__index = TargetMismatchCondition
TargetMismatchCondition.__class = "TargetMismatchCondition"
TargetMismatchCondition.__type = "TargetMismatchCondition"

function TargetMismatchCondition.new(target_index)
    local self = setmetatable(Condition.new(target_index), TargetMismatchCondition)
    return self
end

function TargetMismatchCondition:is_satisfied(target_index)
    local target = player.trust.main_job:get_target()

    local current_target = windower.ffxi.get_mob_by_target('t')
    if current_target == nil then
        return target ~= nil
    end

    if target and target:get_mob() and target:get_mob().index ~= current_target.index then
        return true
    end

    return false
end

function TargetMismatchCondition:tostring()
    return "Target mismatch"
end

function TargetMismatchCondition.description()
    return "Target mismatch."
end

function TargetMismatchCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function TargetMismatchCondition:serialize()
    return "TargetMismatchCondition.new(" .. serializer_util.serialize_args() .. ")"
end

return TargetMismatchCondition




