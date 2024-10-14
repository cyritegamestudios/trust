---------------------------
-- Condition checking whether the player's tp <= max_tp. Does not work on other targets.
-- @class module
-- @name MaxTacticalPointsCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local MaxTacticalPointsCondition = setmetatable({}, { __index = Condition })
MaxTacticalPointsCondition.__index = MaxTacticalPointsCondition
MaxTacticalPointsCondition.__class = "MaxTacticalPointsCondition"
MaxTacticalPointsCondition.__type = "MaxTacticalPointsCondition"

function MaxTacticalPointsCondition.new(max_tp, target_index)
    local self = setmetatable(Condition.new(target_index), MaxTacticalPointsCondition)
    self.max_tp = max_tp or 1000
    return self
end

function MaxTacticalPointsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:get_tp() <= self.max_tp
            end
        end
    end
    return false
end

function MaxTacticalPointsCondition:get_config_items()
    return L{ ConfigItem.new('max_tp', 0, 3000, 100, function(value) return value.."" end, "Max TP") }
end

function MaxTacticalPointsCondition:tostring()
    return "TP <= "..self.max_tp
end

function MaxTacticalPointsCondition.description()
    return "TP <= X."
end

function MaxTacticalPointsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function MaxTacticalPointsCondition:serialize()
    return "MaxTacticalPointsCondition.new(" .. serializer_util.serialize_args(self.max_tp) .. ")"
end

function MaxTacticalPointsCondition:__eq(otherItem)
    return otherItem.__class == MaxTacticalPointsCondition.__class
            and self.max_tp == otherItem.max_tp
end

return MaxTacticalPointsCondition