---------------------------
-- Condition checking whether the target's distance <= distance.
-- @class module
-- @name MaxDistanceCondition

local Condition = require('cylibs/conditions/condition')
local MaxDistanceCondition = setmetatable({}, { __index = Condition })
MaxDistanceCondition.__index = MaxDistanceCondition

function MaxDistanceCondition.new(distance)
    local self = setmetatable(Condition.new(), MaxDistanceCondition)
    self.distance = distance
    return self
end

function MaxDistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.distance:sqrt() <= self.distance
    end
    return false
end

function MaxDistanceCondition:tostring()
    return "MaxDistanceCondition"
end

return MaxDistanceCondition




