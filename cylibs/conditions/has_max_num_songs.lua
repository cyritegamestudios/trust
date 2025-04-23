---------------------------
-- Condition checking whether the player has the maximum number of songs.
-- @class module
-- @name HasMaxNumSongsCondition

local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')

local HasMaxNumSongsCondition = setmetatable({}, { __index = Condition })
HasMaxNumSongsCondition.__index = HasMaxNumSongsCondition
HasMaxNumSongsCondition.__type = "HasMaxNumSongsCondition"
HasMaxNumSongsCondition.__class = "HasMaxNumSongsCondition"

function HasMaxNumSongsCondition.new(operator)
    local self = setmetatable(Condition.new(), HasMaxNumSongsCondition)
    self.operator = operator or Condition.Operator.Equals
    return self
end

function HasMaxNumSongsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            --print(party_member:get_name(), 'max num songs', self.operator, self:eval(party_member:get_num_songs(), party_member:get_max_num_songs(), self.operator))
            return self:eval(party_member:get_num_songs(), party_member:get_max_num_songs(), self.operator)
        end
    end
    return false
end

function HasMaxNumSongsCondition:get_config_items()
    return L{
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function HasMaxNumSongsCondition:tostring()
    return "Has"..' '..self.operator..' max num songs'
end

function HasMaxNumSongsCondition.description()
    return "Has max num songs."
end

function HasMaxNumSongsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function HasMaxNumSongsCondition:serialize()
    return "HasMaxNumSongsCondition.new(" .. serializer_util.serialize_args(self.operator) .. ")"
end

return HasMaxNumSongsCondition





