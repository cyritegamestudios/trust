---------------------------
-- Condition checking whether the target has a specified number of buffs.
-- @class module
-- @name NumBuffsCondition

local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local Condition = require('cylibs/conditions/condition')
local NumBuffsCondition = setmetatable({}, { __index = Condition })
NumBuffsCondition.__index = NumBuffsCondition
NumBuffsCondition.__type = "NumBuffsCondition"
NumBuffsCondition.__class = "NumBuffsCondition"

function NumBuffsCondition.new(num_buffs, operator)
    local self = setmetatable(Condition.new(), NumBuffsCondition)
    self.num_buffs = num_buffs or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function NumBuffsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local monster = player.alliance:get_target_by_index(target.index)
        if monster then
            return self:eval(L(monster:get_buff_ids()):length(), self.num_buffs, self.operator)
        else
            local party_member = player.alliance:get_alliance_member_named(target.name)
            if party_member then
                return self:eval(L(party_member:get_buff_ids()):length(), self.num_buffs, self.operator)
            end
        end
    end
    return false
end

function NumBuffsCondition:get_config_items()
    return L{
        ConfigItem.new('num_buffs', 0, 30, 1, function(value) return value.."" end, "Number of Buffs"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function NumBuffsCondition:tostring()
    return string.format("Has %s %d buffs", self.operator, self.num_buffs)
end

function NumBuffsCondition.description()
    return "Number of buffs."
end

function NumBuffsCondition.valid_targets()
    return Condition.TargetType.AllTargets
end

function NumBuffsCondition:serialize()
    return "NumBuffsCondition.new(" .. serializer_util.serialize_args(self.num_buffs, self.operator) .. ")"
end

function NumBuffsCondition:__eq(otherItem)
    return otherItem.__class == NumBuffsCondition.__class
            and otherItem.num_buffs == self.num_buffs
            and otherItem.operator == self.operator
end

return NumBuffsCondition




