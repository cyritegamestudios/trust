---------------------------
-- Condition checking whether the player's tp >= min_tp. Does not work on other targets.
-- @class module
-- @name MinTacticalPointsCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MinTacticalPointsCondition = setmetatable({}, { __index = Condition })
MinTacticalPointsCondition.__index = MinTacticalPointsCondition
MinTacticalPointsCondition.__class = "MinTacticalPointsCondition"

function MinTacticalPointsCondition.new(min_tp)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), MinTacticalPointsCondition)
    self.min_tp = min_tp
    return self
end

function MinTacticalPointsCondition:is_satisfied(target_index)
    local player = windower.ffxi.get_player()
    if player and player.vitals.tp >= self.min_tp then
        return true
    end
    return false
end

function MinTacticalPointsCondition:tostring()
    return "MinTacticalPointsCondition"
end

function MinTacticalPointsCondition:serialize()
    return "MinTacticalPointsCondition.new(" .. serializer_util.serialize_args(self.min_mp) .. ")"
end

function MinTacticalPointsCondition:__eq(otherItem)
    return otherItem.__class == MinTacticalPointsCondition.__class
            and self.min_tp == otherItem.min_tp
end

return MinTacticalPointsCondition