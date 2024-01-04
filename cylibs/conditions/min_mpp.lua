---------------------------
-- Condition checking whether the player's mpp >= min_mpp. Does not work on other targets.
-- @class module
-- @name MinManaPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MinManaPointsPercentCondition = setmetatable({}, { __index = Condition })
MinManaPointsPercentCondition.__index = MinManaPointsPercentCondition
MinManaPointsPercentCondition.__class = "MinManaPointsPercentCondition"

function MinManaPointsPercentCondition.new(min_mpp)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), MinManaPointsPercentCondition)
    self.min_mpp = min_mpp
    return self
end

function MinManaPointsPercentCondition:is_satisfied(target_index)
    local player = windower.ffxi.get_player()
    if player and player.vitals.mpp >= self.min_mpp then
        return true
    end
    return false
end

function MinManaPointsPercentCondition:tostring()
    return "MinManaPointsPercentCondition"
end

function MinManaPointsPercentCondition:serialize()
    return "MinManaPointsPercentCondition.new(" .. serializer_util.serialize_args(self.min_mpp) .. ")"
end

function MinManaPointsPercentCondition:__eq(otherItem)
    return otherItem.__class == MinManaPointsPercentCondition.__class
            and self.min_mpp == otherItem.min_mpp
end

return MinManaPointsPercentCondition