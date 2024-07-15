---------------------------
-- Condition checking whether the target's mpp <= max_mpp.
-- @class module
-- @name MinHitPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MaxManaPointsPercentCondition = setmetatable({}, { __index = Condition })
MaxManaPointsPercentCondition.__index = MaxManaPointsPercentCondition
MaxManaPointsPercentCondition.__type = "MaxManaPointsPercentCondition"
MaxManaPointsPercentCondition.__class = "MaxManaPointsPercentCondition"

function MaxManaPointsPercentCondition.new(max_mpp)
    local self = setmetatable(Condition.new(), MaxManaPointsPercentCondition)
    self.max_mpp = max_mpp or 100
    return self
end

function MaxManaPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_player()--windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.vitals.mpp <= self.max_mpp
    end
    return false
end

function MaxManaPointsPercentCondition:get_config_items()
    return L{ ConfigItem.new('max_mpp', 0, 100, 1, function(value) return value.." %" end, "Max MP %") }
end

function MaxManaPointsPercentCondition:tostring()
    return "Player MP <= "..self.max_mpp.. "%"
end

function MaxManaPointsPercentCondition:serialize()
    return "MaxManaPointsPercentCondition.new(" .. serializer_util.serialize_args(self.max_mpp) .. ")"
end

return MaxManaPointsPercentCondition




