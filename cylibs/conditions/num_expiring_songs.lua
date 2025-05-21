---------------------------
-- Condition checking the number of expiring songs.
-- @class module
-- @name NumExpiringSongsCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local NumExpiringSongsCondition = setmetatable({}, { __index = Condition })
NumExpiringSongsCondition.__index = NumExpiringSongsCondition
NumExpiringSongsCondition.__type = "NumExpiringSongsCondition"
NumExpiringSongsCondition.__class = "NumExpiringSongsCondition"

function NumExpiringSongsCondition.new(num_required, operator)
    local self = setmetatable(Condition.new(), NumExpiringSongsCondition)
    self.num_required = num_required or 1
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function NumExpiringSongsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            local singer = player.trust.main_job:role_with_type("singer")
            if singer then
                local expiring_duration = singer.song_tracker.expiring_duration
                local num_expiring = party_member:get_songs():filter(function(song_record)
                    return song_record:get_expire_time() - os.time() < expiring_duration
                end):length()
                return self:eval(num_expiring, self.num_required, self.operator)
            end
        end
    end
    return false
end

function NumExpiringSongsCondition:get_config_items()
    return L{
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator"),
        ConfigItem.new('num_required', 0, 5, 1, function(value) return value.."" end, "Num Required"),
    }
end

function NumExpiringSongsCondition:tostring()
    if self.num_required == 1 then
        return string.format("%s 1 song expiring", self.operator)
    else
        return string.format("%s %d songs expiring", self.operator, self.num_required)
    end
end

function NumExpiringSongsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function NumExpiringSongsCondition:serialize()
    return "NumExpiringSongsCondition.new(" .. serializer_util.serialize_args(self.num_required, self.operator) .. ")"
end

function NumExpiringSongsCondition.description()
    return "Number of songs expiring."
end

function NumExpiringSongsCondition:__eq(otherItem)
    return otherItem.__class == NumExpiringSongsCondition.__class
            and self.operator == otherItem.operator
            and self.num_required == otherItem.num_required
end

return NumExpiringSongsCondition




