---------------------------
-- Condition checking whether the player's mp >= min_mp. Does not work on other targets.
-- @class module
-- @name MinManaPointsCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MinManaPointsCondition = setmetatable({}, { __index = Condition })
MinManaPointsCondition.__index = MinManaPointsCondition
MinManaPointsCondition.__class = "MinManaPointsCondition"
MinManaPointsCondition.__type = "MinManaPointsCondition"

function MinManaPointsCondition.new(min_mp)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), MinManaPointsCondition)
    self.min_mp = min_mp or 0
    return self
end

function MinManaPointsCondition:is_satisfied(target_index)
    local player = windower.ffxi.get_player()
    if player and player.vitals.mp >= self.min_mp then
        return true
    end
    return false
end

function MinManaPointsCondition:get_config_items()
    return L{ ConfigItem.new('min_mp', 0, 3000, 50, function(value) return value.."" end) }
end

function MinManaPointsCondition:tostring()
    return "MP >= "..self.min_mp
end

function MinManaPointsCondition:serialize()
    return "MinManaPointsCondition.new(" .. serializer_util.serialize_args(self.min_mp) .. ")"
end

function MinManaPointsCondition:__eq(otherItem)
    return otherItem.__class == MinManaPointsCondition.__class
            and self.min_mp == otherItem.min_mp
end

return MinManaPointsCondition