---------------------------
-- Condition checking whether the target's distance <= distance.
-- @class module
-- @name MaxDistanceCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MaxDistanceCondition = setmetatable({}, { __index = Condition })
MaxDistanceCondition.__index = MaxDistanceCondition
MaxDistanceCondition.__class = "MaxDistanceCondition"
MaxDistanceCondition.__type = "MaxDistanceCondition"

function MaxDistanceCondition.new(distance, target_index)
    local self = setmetatable(Condition.new(target_index), MaxDistanceCondition)
    self.distance = distance or 20
    return self
end

function MaxDistanceCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.distance:sqrt() <= self.distance
    end
    return false
end

function MaxDistanceCondition:get_config_items()
    return L{
        ConfigItem.new('distance', 0, 50, 1, function(value) return value.." yalms" end),
    }
end

function MaxDistanceCondition:tostring()
    return "Target distance <= "..self.distance.. " yalms"
end

function MaxDistanceCondition:serialize()
    return "MaxDistanceCondition.new(" .. serializer_util.serialize_args(self.distance) .. ")"
end

return MaxDistanceCondition




