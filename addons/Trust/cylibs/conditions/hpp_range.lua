---------------------------
-- Condition checking whether min_hpp <= target's hpp <= max_hpp.
-- @class module
-- @name MinHitPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HitPointsPercentRangeCondition = setmetatable({}, { __index = Condition })
HitPointsPercentRangeCondition.__index = HitPointsPercentRangeCondition

function HitPointsPercentRangeCondition.new(min_hpp, max_hpp, target)
    local self = setmetatable(Condition.new(), HitPointsPercentRangeCondition)
    self.min_hpp = min_hpp
    self.max_hpp = max_hpp
    self.target = target
    return self
end

function HitPointsPercentRangeCondition:is_satisfied(target_index)
    local target = self.target or windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.hpp >= self.min_hpp and target.hpp <= self.max_hpp
    end
    return false
end

function HitPointsPercentRangeCondition:tostring()
    return "HitPointsPercentRangeCondition"
end

function HitPointsPercentRangeCondition:serialize()
    return "HitPointsPercentRangeCondition.new(" .. serializer_util.serialize_args(self.min_hpp, self.max_hpp) .. ")"
end

return HitPointsPercentRangeCondition




