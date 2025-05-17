local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local SongStatusView = setmetatable({}, {__index = ConfigEditor })
SongStatusView.__index = SongStatusView


function SongStatusView.new(singer)
    local partyMembers = singer:get_party():get_party_members(true)

    local songSettings = {
        PartyMember = partyMembers[1], -- FIXME: this is getting destroyed which is removing buff listeners
    }

    local maxNumSongs = singer.job.max_num_songs + 1

    local configItemsForPartyMember = function(partyMember)
        local partyMemberItem = PickerConfigItem.new('PartyMember', songSettings.PartyMember, partyMembers, function(p) return p:get_name() end, "Party Member")

        for i = 1, 5 do
            songSettings['Song'..i] = nil
        end

        local songItems = L{}
        local songIndex = 1
        local songRecords = singer.song_tracker:get_songs(partyMember:get_id())
        for songRecord in songRecords:it() do
            local songName = spell_util.spell_name(songRecord:get_song_id())..' ('..songRecord:get_time_remaining()..'s)'
            local tempIndex = songIndex
            songSettings['Song'..songIndex] = songName
            local songItem = PickerConfigItem.new('Song'..songIndex, songName, L{ songName }, function(v) if v then return v else return 'Any' end end, "Song "..songIndex)
            if tempIndex == maxNumSongs then
                songItem.description = songItem.description.." (Clarion Call)"
            end
            songItems:append(songItem)
            songIndex = songIndex + 1
        end

        return L{ partyMemberItem } + songItems
    end

    local self = setmetatable(ConfigEditor.new(nil, songSettings, configItemsForPartyMember(partyMembers[1])), SongStatusView)

    self:getDisposeBag():add(self:onConfigItemChanged():addAction(function(key, value, configItem)
        if key == 'PartyMember' then
            songSettings.PartyMember = value
            self:getDataSource():removeAllSections()
            self:setConfigItems(configItemsForPartyMember(value))
            self:reloadSettings()
        end
    end), self:onConfigItemChanged())

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.section > 1 then
            addon_system_message("You cannot edit songs from this menu.")
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    return self
end

return SongStatusView