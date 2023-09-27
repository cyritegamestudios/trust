---------------------------
-- Condition checking whether the target's hpp >= min_hpp.
-- @class module
-- @name MinHitPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MinHitPointsPercentCondition = setmetatable({}, { __index = Condition })
MinHitPointsPercentCondition.__index = MinHitPointsPercentCondition

function MinHitPointsPercentCondition.new(min_hpp)
    local self = setmetatable(Condition.new(), MinHitPointsPercentCondition)
    self.min_hpp = min_hpp
    return self
end

function MinHitPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.hpp >= self.min_hpp
    end
    return false
end

function MinHitPointsPercentCondition:tostring()
    return "MinHitPointsPercentCondition"
end

function MinHitPointsPercentCondition:serialize()
    return "MinHitPointsPercentCondition.new(" .. serializer_util.serialize_args(self.min_hpp) .. ")"
end

return MinHitPointsPercentCondition




