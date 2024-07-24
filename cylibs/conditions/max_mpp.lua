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

function MaxManaPointsPercentCondition.new(max_mpp, target_index)
    local self = setmetatable(Condition.new(target_index), MaxManaPointsPercentCondition)
    self.max_mpp = max_mpp or 100
    return self
end

function MaxManaPointsPercentCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:get_mpp() <= self.max_mpp
            end
        end
    end
    return false
end

function MaxManaPointsPercentCondition:get_config_items()
    return L{ ConfigItem.new('max_mpp', 0, 100, 1, function(value) return value.." %" end, "Max MP %") }
end

function MaxManaPointsPercentCondition:tostring()
    return "MP <= "..self.max_mpp.. "%"
end

function MaxManaPointsPercentCondition.description()
    return "MP <= X%."
end

function MaxManaPointsPercentCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function MaxManaPointsPercentCondition:serialize()
    return "MaxManaPointsPercentCondition.new(" .. serializer_util.serialize_args(self.max_mpp) .. ")"
end

return MaxManaPointsPercentCondition




