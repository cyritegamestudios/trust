---------------------------
-- Condition checking whether the target is idle.
-- @class module
-- @name IdleCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local IdleCondition = setmetatable({}, { __index = Condition })
IdleCondition.__index = IdleCondition
IdleCondition.__type = "IdleCondition"
IdleCondition.__class = "IdleCondition"

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
    return "Is idle"
end

function IdleCondition.description()
    return "Target is not in battle."
end

function IdleCondition:serialize()
    return "IdleCondition.new(" .. serializer_util.serialize_args() .. ")"
end

function IdleCondition:__eq(otherItem)
    return otherItem.__class == IdleCondition.__class
end

return IdleCondition




