local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local SongListEditor = setmetatable({}, {__index = ConfigEditor })
SongListEditor.__index = SongListEditor


function SongListEditor.new(singer)
    local partyMember = singer:get_party():get_player()

    local songSettings = {
        PartyMember = partyMember:get_name(),
    }

    local configItems = L{
    }

    local mergedSongs = singer:get_merged_songs(partyMember)
    local songItems = L{}

    local songIndex = 1
    for song in mergedSongs:it() do
        local tempIndex = songIndex
        songSettings['Song'..songIndex] = song:get_spell().en
        local songItem = PickerConfigItem.new('Song'..songIndex, song:get_spell().en, L{ song:get_spell().en }, function(v) if v then return v else return 'None' end end, "Song "..songIndex)
        songItem.onReload = function(key, newValue, configItem)
            songSettings.PartyMember = newValue
            configItem.initialValue = newValue
            local partyMember = singer:get_party():get_party_member_named(newValue)
            if partyMember:get_main_job_short() == 'NON' then
                addon_system_error("Song "..tempIndex.." may be incorrect because party member main job is unknown.")
            end
            return L{ singer:get_merged_songs(partyMember)[tempIndex] }:map(function(s) return s:get_spell().en end)
        end
        songItems:append(songItem)
        songIndex = songIndex + 1
    end

    local partyMemberItem = PickerConfigItem.new('PartyMember', songSettings.PartyMember, singer:get_party():get_party_members(true):map(function(p) return p:get_name() end), nil, "Party Member")
    partyMemberItem.dependencies = songItems

    configItems:append(partyMemberItem)

    for songItem in songItems:it() do
        configItems:append(songItem)
    end

    local self = setmetatable(ConfigEditor.new(nil, songSettings, configItems), SongListEditor)
    return self
end

return SongListEditor