---------------------------
-- Condition checking whether the target's hpp <= max_hpp.
-- @class module
-- @name MinHitPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MaxHitPointsPercentCondition = setmetatable({}, { __index = Condition })
MaxHitPointsPercentCondition.__index = MaxHitPointsPercentCondition
MaxHitPointsPercentCondition.__type = "MaxHitPointsPercentCondition"
MaxHitPointsPercentCondition.__class = "MaxHitPointsPercentCondition"

function MaxHitPointsPercentCondition.new(max_hpp, target_index)
    local self = setmetatable(Condition.new(target_index), MaxHitPointsPercentCondition)
    self.max_hpp = max_hpp or 100
    return self
end

function MaxHitPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.hpp <= self.max_hpp
    end
    return false
end

function MaxHitPointsPercentCondition:get_config_items()
    return L{ ConfigItem.new('max_hpp', 0, 100, 1, function(value) return value.." %" end, "Max HP %") }
end

function MaxHitPointsPercentCondition:tostring()
    return "HP <= "..self.max_hpp.. "%"
end

function MaxHitPointsPercentCondition.description()
    return "HP <= X%."
end

function MaxHitPointsPercentCondition:serialize()
    return "MaxHitPointsPercentCondition.new(" .. serializer_util.serialize_args(self.max_hpp) .. ")"
end

return MaxHitPointsPercentCondition




