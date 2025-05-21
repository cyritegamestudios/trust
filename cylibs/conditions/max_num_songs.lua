---------------------------
-- Condition checking the maximum number of songs allowed on the target.
-- @class module
-- @name MaxNumSongsCondition

local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')

local MaxNumSongsCondition = setmetatable({}, { __index = Condition })
MaxNumSongsCondition.__index = MaxNumSongsCondition
MaxNumSongsCondition.__type = "MaxNumSongsCondition"
MaxNumSongsCondition.__class = "MaxNumSongsCondition"

function MaxNumSongsCondition.new(num_songs, operator)
    local self = setmetatable(Condition.new(), MaxNumSongsCondition)
    self.num_songs = num_songs
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function MaxNumSongsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            local max_num_songs = party_member:get_max_num_songs()
            return self:eval(max_num_songs, self.num_songs, self.operator)
        end
    end
    return false
end

function MaxNumSongsCondition:get_config_items()
    return L{
        ConfigItem.new('num_songs', 1, 5, 1, nil, "Number of Songs"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function MaxNumSongsCondition:tostring()
    return string.format("Maximum number of songs %s %d", self.operator, self.num_songs)
end

function MaxNumSongsCondition.description()
    return "Maximum number of songs."
end

function MaxNumSongsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function MaxNumSongsCondition:serialize()
    return "MaxNumSongsCondition.new(" .. serializer_util.serialize_args(self.num_songs, self.operator) .. ")"
end

return MaxNumSongsCondition





