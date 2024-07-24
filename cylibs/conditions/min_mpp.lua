---------------------------
-- Condition checking whether the player's mpp >= min_mpp. Does not work on other targets.
-- @class module
-- @name MinManaPointsPercentCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MinManaPointsPercentCondition = setmetatable({}, { __index = Condition })
MinManaPointsPercentCondition.__index = MinManaPointsPercentCondition
MinManaPointsPercentCondition.__class = "MinManaPointsPercentCondition"
MinManaPointsPercentCondition.__type = "MinManaPointsPercentCondition"

function MinManaPointsPercentCondition.new(min_mpp, target_index)
    local self = setmetatable(Condition.new(target_index), MinManaPointsPercentCondition)
    self.min_mpp = min_mpp or 0
    return self
end

function MinManaPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:get_mpp() >= self.min_mpp
            end
        end
    end
    return false
end

function MinManaPointsPercentCondition:get_config_items()
    return L{ ConfigItem.new('min_mpp', 0, 100, 1, function(value) return value.." %" end, "Min MP %") }
end

function MinManaPointsPercentCondition:tostring()
    return "MP >= "..self.min_mpp.. "%"
end

function MinManaPointsPercentCondition.description()
    return "MP >= X%."
end

function MinManaPointsPercentCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function MinManaPointsPercentCondition:serialize()
    return "MinManaPointsPercentCondition.new(" .. serializer_util.serialize_args(self.min_mpp) .. ")"
end

function MinManaPointsPercentCondition:__eq(otherItem)
    return otherItem.__class == MinManaPointsPercentCondition.__class
            and self.min_mpp == otherItem.min_mpp
end

return MinManaPointsPercentCondition