---------------------------
-- Condition checking whether the target is claimed, optionally by a specific player.
-- @class module
-- @name ClaimedCondition

local Condition = require('cylibs/conditions/condition')
local ClaimedCondition = setmetatable({}, { __index = Condition })
ClaimedCondition.__index = ClaimedCondition
ClaimedCondition.__type = "ClaimedCondition"
ClaimedCondition.__class = "ClaimedCondition"

function ClaimedCondition.new(claim_ids)
    local self = setmetatable(Condition.new(), ClaimedCondition)
    self.claim_ids = claim_ids or L{}
    return self
end

function ClaimedCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        if self.claim_ids and self.claim_ids:length() > 0 then
            return self.claim_ids:contains(target.claim_id)
        else
            return target.claim_id and target.claim_id ~= 0
        end
    end
    return false
end

function ClaimedCondition:tostring()
    local target_names = self.claim_ids:map(function(claim_id) return windower.ffxi.get_mob_by_id(claim_id) end):compact_map():map(function(mob) return mob.name end)
    if target_names:length() > 0 then
        return "Target is claimed by "..localization_util.commas(target_names, 'or')
    end
    return "Target is claimed"
end

function ClaimedCondition.description()
    return "Target is claimed."
end

function ClaimedCondition.valid_targets()
    return S{ Condition.TargetType.Enemy }
end

function ClaimedCondition:__eq(otherItem)
    return otherItem.__class == ClaimedCondition.__class
end

return ClaimedCondition




