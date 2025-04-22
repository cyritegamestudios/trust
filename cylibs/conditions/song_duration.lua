---------------------------
-- Condition checking remaining song duration.
-- @class module
-- @name SongDurationCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local SongDurationCondition = setmetatable({}, { __index = Condition })
SongDurationCondition.__index = SongDurationCondition
SongDurationCondition.__type = "SongDurationCondition"
SongDurationCondition.__class = "SongDurationCondition"

function SongDurationCondition.new(song_names, duration, operator)
    local self = setmetatable(Condition.new(), SongDurationCondition)
    self.song_names = song_names or L{ "Army's Paeon" }
    self.duration = duration or 60
    self.operator = operator or Condition.Operator.GreaterThanOrEqualTo
    return self
end

function SongDurationCondition:check_song(song_name, active_songs)
    local song_id = spell_util.spell_id(song_name)
    for song in active_songs:it() do
        if song:get_song_id() == song_id then
            return self:eval(song:get_time_remaining(), self.duration, self.operator)
        end
    end
    return false
end

function SongDurationCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            local active_songs = party_member:get_songs()
            for song_name in self.song_names:it() do
                if not self:check_song(song_name, active_songs) then
                    return false
                end
            end
            return true
        end
    end
    return false
end

function SongDurationCondition:get_config_items()
    local all_songs = L(res.spells:with_all('type', 'BardSong')):filter(function(song)
        return S{'Self'}:intersection(S(song.targets)):length() > 0
    end):map(function(song)
        return song.en
    end)
    return L{
        MultiPickerConfigItem.new('song_names', self.song_names, all_songs, function(song_names)
            if song_names:length() == 0 then
                return 'None'
            end
            return localization_util.commas(song_names)
        end, "Song Names"),
        ConfigItem.new('duration', 0, 800, 10, function(value) return value.."s" end, "Song Duration"),
        PickerConfigItem.new('operator', self.operator, L{ Condition.Operator.GreaterThanOrEqualTo, Condition.Operator.Equals, Condition.Operator.GreaterThan, Condition.Operator.LessThan, Condition.Operator.LessThanOrEqualTo }, nil, "Operator")
    }
end

function SongDurationCondition:tostring()
    if self.song_names:length() == 0 then
        return string.format("%s has %s %ss remaining", self.song_names[1], self.operator, self.duration)
    end
    return string.format('%s have %s %ss remaining', localization_util.commas(self.song_names), self.operator, self.duration)
end

function SongDurationCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function SongDurationCondition:serialize()
    return "SongDurationCondition.new(" .. serializer_util.serialize_args(self.song_names, self.duration, self.operator) .. ")"
end

function SongDurationCondition.description()
    return "Song duration remaining."
end

function SongDurationCondition:__eq(otherItem)
    return otherItem.__class == SongDurationCondition.__class
            and self.strategem_count == otherItem.strategem_count
            and self.operator == otherItem.operator
end

return SongDurationCondition




