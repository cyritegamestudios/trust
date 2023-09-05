---------------------------
-- Condition checking whether min_hpp <= target's hpp <= max_hpp.
-- @class module
-- @name MinHitPointsPercentCondition

local Condition = require('cylibs/conditions/condition')
local HitPointsPercentRangeCondition = setmetatable({}, { __index = Condition })
HitPointsPercentRangeCondition.__index = HitPointsPercentRangeCondition

function HitPointsPercentRangeCondition.new(min_hpp, max_hpp)
    local self = setmetatable(Condition.new(), HitPointsPercentRangeCondition)
    self.min_hpp = min_hpp
    self.max_hpp = max_hpp
    return self
end

function HitPointsPercentRangeCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.hpp >= self.min_hpp and target.hpp <= self.max_hpp
    end
    return false
end

function HitPointsPercentRangeCondition:tostring()
    return "HitPointsPercentRangeCondition"
end

return HitPointsPercentRangeCondition




