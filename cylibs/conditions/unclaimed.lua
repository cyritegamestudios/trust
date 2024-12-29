---------------------------
-- Condition checking whether the target is unclaimed.
-- @class module
-- @name UnclaimedCondition

local Condition = require('cylibs/conditions/condition')
local UnclaimedCondition = setmetatable({}, { __index = Condition })
UnclaimedCondition.__index = UnclaimedCondition
UnclaimedCondition.__type = "UnclaimedCondition"
UnclaimedCondition.__class = "UnclaimedCondition"

function UnclaimedCondition.new(target_index)
    local self = setmetatable(Condition.new(target_index), UnclaimedCondition)
    return self
end

function UnclaimedCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        return target.claim_id == nil or target.claim_id == 0
    end
    return false
end

function UnclaimedCondition:tostring()
    return "UnclaimedCondition"
end

function UnclaimedCondition.description()
    return "Target is unclaimed."
end

function UnclaimedCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function UnclaimedCondition:__eq(otherItem)
    return otherItem.__class == UnclaimedCondition.__class
end

return UnclaimedCondition




