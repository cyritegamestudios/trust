---------------------------
-- Condition checking a target's status, optionally for a specified duration.
-- @class module
-- @name StatusCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local StatusCondition = setmetatable({}, { __index = Condition })
StatusCondition.__index = StatusCondition
StatusCondition.__type = "StatusCondition"
StatusCondition.__class = "StatusCondition"

function StatusCondition.new(status_name, duration, operator)
    local self = setmetatable(Condition.new(), StatusCondition)
    self.status_name = status_name or 'Idle'
    self.duration = duration or 0
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function StatusCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:get_status() == self.status_name
                        and self:eval(party_member:get_status_duration(), self.duration, self.operator)
            end
        end
    end
    return false
end

function StatusCondition:get_config_items()
    local allStatuses = L{ 0, 1, 2, 3, 4, 5, 33, 44, 85 }:map(function(status_id)
        return res.statuses[status_id].en
    end):compact_map()
    return L{
        PickerConfigItem.new('status_name', self.status_name, allStatuses, nil, "Status"),
        ConfigItem.new('duration', 0, 60, 1, function(value) return value.."s" end, "Time in Status"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function StatusCondition:tostring()
    return "Is "..self.status_name.." for "..self.operator.." "..self.duration.."s"
end

function StatusCondition.description()
    return "Status is X."
end

function StatusCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function StatusCondition:serialize()
    return "StatusCondition.new(" .. serializer_util.serialize_args(self.status_name, self.duration, self.operator) .. ")"
end

return StatusCondition




