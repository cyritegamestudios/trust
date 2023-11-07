---------------------------
-- Condition checking whether the target is idle.
-- @class module
-- @name IdleCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local IdleCondition = setmetatable({}, { __index = Condition })
IdleCondition.__index = IdleCondition
IdleCondition.__type = "IdleCondition"

function IdleCondition.new()
    local self = setmetatable(Condition.new(), IdleCondition)
    return self
end

function IdleCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.status == 0
    end
    return false
end

function IdleCondition:tostring()
    return "IdleCondition"
end

function IdleCondition:serialize()
    return "IdleCondition.new(" .. serializer_util.serialize_args() .. ")"
end

return IdleCondition




