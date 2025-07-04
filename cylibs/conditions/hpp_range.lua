---------------------------
-- Condition checking whether min_hpp <= target's hpp <= max_hpp.
-- @class module
-- @name MinHitPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HitPointsPercentRangeCondition = setmetatable({}, { __index = Condition })
HitPointsPercentRangeCondition.__index = HitPointsPercentRangeCondition
HitPointsPercentRangeCondition.__class = "HitPointsPercentRangeCondition"
HitPointsPercentRangeCondition.__type = "HitPointsPercentRangeCondition"

function HitPointsPercentRangeCondition.new(min_hpp, max_hpp, target_index)
    local self = setmetatable(Condition.new(target_index), HitPointsPercentRangeCondition)
    self.min_hpp = min_hpp or 0
    self.max_hpp = max_hpp or 100
    return self
end

function HitPointsPercentRangeCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.hpp >= self.min_hpp and target.hpp <= self.max_hpp
    end
    return false
end

function HitPointsPercentRangeCondition:get_config_items()
    return L{
        ConfigItem.new('min_hpp', 0, 100, 1, function(value) return value.." %" end, "Min HP %"),
        ConfigItem.new('max_hpp', 0, 100, 1, function(value) return value.." %" end, "Max HP %"),
    }
end

function HitPointsPercentRangeCondition:tostring()
    return 'HP >= '..self.min_hpp..'% and HP <= '..self.max_hpp..'%'
end

function HitPointsPercentRangeCondition.description()
    return "HP >= X% and HP <= Y%"
end

function HitPointsPercentRangeCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function HitPointsPercentRangeCondition:serialize()
    return "HitPointsPercentRangeCondition.new(" .. serializer_util.serialize_args(self.min_hpp, self.max_hpp) .. ")"
end

return HitPointsPercentRangeCondition




