---------------------------
-- Condition checking whether the target's hpp <= max_hpp.
-- @class module
-- @name MinHitPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

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

function MaxHitPointsPercentCondition:tostring()
    return "MaxHitPointsPercentCondition"
end

function MaxHitPointsPercentCondition:serialize()
    return "MaxHitPointsPercentCondition.new(" .. serializer_util.serialize_args(self.max_hpp) .. ")"
end

return MaxHitPointsPercentCondition




