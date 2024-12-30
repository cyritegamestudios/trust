---------------------------
-- Condition checking whether the target is aggroed to the party.
-- @class module
-- @name IsAggroedCondition

local Condition = require('cylibs/conditions/condition')
local IsAggroedCondition = setmetatable({}, { __index = Condition })
IsAggroedCondition.__index = IsAggroedCondition
IsAggroedCondition.__type = "IsAggroedCondition"
IsAggroedCondition.__class = "IsAggroedCondition"

function IsAggroedCondition.new()
    local self = setmetatable(Condition.new(), IsAggroedCondition)
    return self
end

function IsAggroedCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local monster = player.alliance:get_target_by_index(target_index)
        return monster and monster:get_status() == 'Engaged'
    end
    return false
end

function IsAggroedCondition:tostring()
    return "Target is aggroed"
end

function IsAggroedCondition.description()
    return "Target is aggroed."
end

function IsAggroedCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function IsAggroedCondition:__eq(otherItem)
    return otherItem.__class == IsAggroedCondition.__class
end

return IsAggroedCondition




