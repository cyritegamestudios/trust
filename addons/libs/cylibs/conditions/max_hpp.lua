---------------------------
-- Condition checking whether the target's hpp <= max_hpp.
-- @class module
-- @name MinHitPointsPercentCondition

local Condition = require('cylibs/conditions/condition')
local MaxHitPointsPercentCondition = setmetatable({}, { __index = Condition })
MaxHitPointsPercentCondition.__index = MaxHitPointsPercentCondition

function MaxHitPointsPercentCondition.new(max_hpp)
    local self = setmetatable(Condition.new(), MaxHitPointsPercentCondition)
    self.max_hpp = max_hpp
    return self
end

function MaxHitPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.hpp <= self.max_hpp
    end
    return false
end

return MaxHitPointsPercentCondition




