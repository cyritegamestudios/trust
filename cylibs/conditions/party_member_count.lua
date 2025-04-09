---------------------------
-- Condition checking whether the player has the specified number of party members.
-- @class module
-- @name PartyMemberCountCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local PartyMemberCountCondition = setmetatable({}, { __index = Condition })
PartyMemberCountCondition.__index = PartyMemberCountCondition
PartyMemberCountCondition.__type = "PartyMemberCountCondition"
PartyMemberCountCondition.__class = "PartyMemberCountCondition"

function PartyMemberCountCondition.new(member_count, operator)
    local self = setmetatable(Condition.new(), PartyMemberCountCondition)
    self.member_count = member_count or 6
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function PartyMemberCountCondition:is_satisfied(_)
    local party = player.party
    if party then
        return self:eval(party:get_party_members(true):length(), self.member_count, self.operator)
    end
    return false
end

function PartyMemberCountCondition:get_config_items()
    return L{
        ConfigItem.new('member_count', 0, 5, 1, function(value) return value.."" end, "Number of Party Members"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function PartyMemberCountCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function PartyMemberCountCondition:serialize()
    return "PartyMemberCountCondition.new(" .. serializer_util.serialize_args(self.member_count, self.operator) .. ")"
end

function PartyMemberCountCondition:tostring()
    return "Has "..' '..self.operator..' '..self.member_count..' party members'
end

function PartyMemberCountCondition.description()
    return "Number of party members."
end

function PartyMemberCountCondition:__eq(otherItem)
    return otherItem.__class == PartyMemberCountCondition.__class
            and self.member_count == otherItem.member_count
            and self.operator == otherItem.operator
end

return PartyMemberCountCondition




