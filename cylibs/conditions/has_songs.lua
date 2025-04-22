---------------------------
-- Condition checking whether the player has the given songs.
-- @class module
-- @name HasSongsCondition

local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local localization_util = require('cylibs/util/localization_util')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local HasSongsCondition = setmetatable({}, { __index = Condition })
HasSongsCondition.__index = HasSongsCondition
HasSongsCondition.__type = "HasSongsCondition"
HasSongsCondition.__class = "HasSongsCondition"

function HasSongsCondition.new(song_names, num_required)
    local self = setmetatable(Condition.new(), HasSongsCondition)
    self.song_names = song_names or L{ 'Valor Minuet V' }
    self.num_required = num_required or self.song_names:length()
    return self
end

function HasSongsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            local active_song_names = self.song_names:filter(function(song_name)
                return party_member:has_song(spell_util.spell_id(song_name))
            end)
            return active_song_names:length() >= self.num_required
        end
    end
    return false
end

function HasSongsCondition:get_config_items()
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
        ConfigItem.new('num_required', 1, 10, 1, nil, "Number Required"),
    }
end

function HasSongsCondition:tostring()
    local song_names = L((self.song_names or L{}):map(function(song_name)
        return i18n.resource('spells', 'en', song_name)
    end))
    if song_names:length() == self.num_required then
        return "Has "..localization_util.commas(song_names)
    else
        return "Has "..self.num_required.."+ of "..localization_util.commas(song_names)
    end
end

function HasSongsCondition.description()
    return "Has one or more songs."
end

function HasSongsCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function HasSongsCondition:serialize()
    return "HasSongsCondition.new(" .. serializer_util.serialize_args(self.song_names, self.num_required) .. ")"
end

return HasSongsCondition




