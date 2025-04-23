---------------------------
-- Condition checking whether the player has the given number of songs.
-- @class module
-- @name NumSongsCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local NumSongsCondition = setmetatable({}, { __index = Condition })
NumSongsCondition.__index = NumSongsCondition
NumSongsCondition.__type = "NumSongsCondition"
NumSongsCondition.__class = "NumSongsCondition"

function NumSongsCondition.new(num_songs, operator)
    local self = setmetatable(Condition.new(), NumSongsCondition)
    self.num_songs = num_songs or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function NumSongsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            return self:eval(party_member:get_num_songs(), self.num_songs, self.operator)
        end
    end
    return false
end

function NumSongsCondition:get_config_items()
    return L{
        ConfigItem.new('num_songs', 1, 5, 1, nil, "Number of Songs"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function NumSongsCondition:tostring()
    return "Has"..' '..self.operator..' '..self.num_songs..' songs'
end

function NumSongsCondition.description()
    return "Number of songs."
end

function NumSongsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function NumSongsCondition:serialize()
    return "NumSongsCondition.new(" .. serializer_util.serialize_args(self.num_songs, self.operator) .. ")"
end

return NumSongsCondition





