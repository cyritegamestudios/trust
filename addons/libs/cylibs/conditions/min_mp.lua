---------------------------
-- Condition checking whether the player's mp >= min_mp. Does not work on other targets.
-- @class module
-- @name MinHitPointsPercentCondition

local Condition = require('cylibs/conditions/condition')
local MinManaPointsCondition = setmetatable({}, { __index = Condition })
MinManaPointsCondition.__index = MinManaPointsCondition

function MinManaPointsCondition.new(min_mp)
    local self = setmetatable(Condition.new(), MinManaPointsCondition)
    self.min_mp = min_mp
    return self
end

function MinManaPointsCondition:is_satisfied(target_index)
    local player = windower.ffxi.get_player()
    if player and player.vitals.mp >= self.min_mp then
        return true
    end
    return false
end

function MinManaPointsCondition:is_player_only()
    return true
end

function MinManaPointsCondition:tostring()
    return "MinManaPointsCondition"
end

return MinManaPointsCondition




