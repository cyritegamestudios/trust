---------------------------
-- Condition checking whether a certain number of enemies are nearby and claimed.
-- @class module
-- @name EnemiesNearbyCondition
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local EnemiesNearbyCondition = setmetatable({}, { __index = Condition })
EnemiesNearbyCondition.__index = EnemiesNearbyCondition
EnemiesNearbyCondition.__class = "EnemiesNearbyCondition"
EnemiesNearbyCondition.__type = "EnemiesNearbyCondition"

function EnemiesNearbyCondition.new(num_required, distance, operator)
    local self = setmetatable(Condition.new(), EnemiesNearbyCondition)
    self.num_required = num_required or 4
    self.distance = distance or 12
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function EnemiesNearbyCondition:is_satisfied(_)
    local party_targets = player.party:get_targets(function(m)
        return m:get_mob() and m:get_mob().distance:sqrt() < self.distance
    end)
    return self:eval(party_targets:length(), self.num_required, self.operator)
end

function EnemiesNearbyCondition:get_config_items()
    return L{
        ConfigItem.new('num_required', 1, 30, 1, function(value) return value.."" end, "Number of Enemies"),
        ConfigItem.new('distance', 1, 30, 1, function(value) return value.." yalms" end, "Distance from Player"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function EnemiesNearbyCondition:tostring()
    if self.num_required == 1 then
        return self.operator.." "..self.num_required.." enemy within "..self.distance.." yalms"
    else
        return self.operator.." "..self.num_required.." enemies within "..self.distance.." yalms"
    end
end

function EnemiesNearbyCondition.description()
    return "Number of enemies nearby."
end

function EnemiesNearbyCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function EnemiesNearbyCondition:serialize()
    return "EnemiesNearbyCondition.new(" .. serializer_util.serialize_args(self.num_required, self.distance, self.operator) .. ")"
end

function EnemiesNearbyCondition:__eq(otherItem)
    return otherItem.__class == EnemiesNearbyCondition.__class
            and self.num_required == otherItem.num_required
            and self.distance == otherItem.distance
            and self.operator == otherItem.operator
end

return EnemiesNearbyCondition