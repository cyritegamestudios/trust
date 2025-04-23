local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local SongListEditor = setmetatable({}, {__index = ConfigEditor })
SongListEditor.__index = SongListEditor


function SongListEditor.new(singer)
    local partyMembers = job_util.all_jobs():map(function(jobNameShort)
        local partyMember = PartyMember.new(res.jobs:with('ens', jobNameShort).id, jobNameShort)
        partyMember.main_job_short = jobNameShort
        return partyMember
    end)

    local songSettings = {
        PartyMember = partyMembers[1],
    }

    local configItems = L{}

    local maxNumSongs = singer.job.max_num_songs + 1
    local mergedSongs = singer:get_merged_songs(partyMembers[1], maxNumSongs):reverse()
    local songItems = L{}

    local songIndex = 1
    for song in mergedSongs:it() do
        local tempIndex = songIndex
        songSettings['Song'..songIndex] = song:get_spell().en
        local songItem = PickerConfigItem.new('Song'..songIndex, song:get_spell().en, L{ song:get_spell().en }, function(v) if v then return v else return 'Any' end end, "Song "..songIndex)
        if tempIndex == maxNumSongs then
            songItem.description = songItem.description.." (Clarion Call)"
        end
        songItem.onReload = function(key, newValue, configItem)
            songSettings.PartyMember = newValue
            configItem.initialValue = newValue
            return L{ singer:get_merged_songs(newValue, maxNumSongs):reverse()[tempIndex] }:map(function(s) return s:get_spell().en end)
        end
        songItems:append(songItem)
        songIndex = songIndex + 1
    end

    local partyMemberItem = PickerConfigItem.new('PartyMember', songSettings.PartyMember, partyMembers, function(p) return res.jobs:with('ens', p:get_name()).en end, "Party Member Job")
    partyMemberItem.dependencies = songItems

    configItems:append(partyMemberItem)

    for songItem in songItems:it() do
        configItems:append(songItem)
    end

    local self = setmetatable(ConfigEditor.new(nil, songSettings, configItems), SongListEditor)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.section > 1 then
            addon_system_message("You cannot edit songs from this menu.")
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():addAny(partyMembers)

    return self
end

return SongListEditor