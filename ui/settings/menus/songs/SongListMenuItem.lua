local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local SongListMenuItem = setmetatable({}, {__index = MenuItem })
SongListMenuItem.__index = SongListMenuItem

function SongListMenuItem.new(trust, trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Jobs', 18),
    }, {}, nil, "Songs", "Choose 5 songs to sing."), SongListMenuItem)

    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local songs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings.Songs

        local allSongs = trust:get_job():get_spells(function(spell_id)
            local spell = res.spells[spell_id]
            return spell and spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell_id)
            return res.spells[spell_id].en
        end):sort()

        local songSettings = {
            Song1 = songs[1]:get_name(),
            Song2 = songs[2]:get_name(),
            Song3 = songs[3]:get_name(),
            Song4 = songs[4]:get_name(),
            Song5 = songs[5]:get_name()
        }

        local configItems = L{
            PickerConfigItem.new('Song1', songSettings.Song1, allSongs, nil, "Song 1 (Marcato)"),
            PickerConfigItem.new('Song2', songSettings.Song2, allSongs, nil, "Song 2"),
            PickerConfigItem.new('Song3', songSettings.Song3, allSongs, nil, "Song 3"),
            PickerConfigItem.new('Song4', songSettings.Song4, allSongs, nil, "Song 4"),
            PickerConfigItem.new('Song5', songSettings.Song5, allSongs, nil, "Song 5"),
        }

        local songConfigEditor = ConfigEditor.new(nil, songSettings, configItems, infoView, function(newSettings)
            local newSongNames = L{}
            for _, songName in pairs(newSettings) do
                newSongNames:append(songName)
            end
            if S(newSongNames):length() ~= 5 then
                return false
            end
            return true
        end)

        self.disposeBag:add(songConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            self.selectedSongIndex = indexPath.section
            
            local song = songs[self.selectedSongIndex]
            if song then
                if song:get_job_names():length() > 0 then
                    infoView:setDescription("Use when: Ally job is "..localization_util.commas(song:get_job_names(), "or"))
                else
                    infoView:setDescription("Use when: Never (no jobs selected)")
                end
            end
        end), songConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        self.disposeBag:add(songConfigEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
            local songs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings.Songs
            for i = 1, 5 do
                local newSongName = newSettings["Song"..i]
                if songs[i]:get_name() ~= newSongName then
                    local jobAbilities = L{}
                    if i == 1 then
                        jobAbilities = L{ "Marcato"}
                    end
                    songs[i] = Spell.new(newSongName, jobAbilities, job_util.all_jobs())
                end
            end

            trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")
        end), songConfigEditor:onConfigChanged())

        self.disposeBag:add(songConfigEditor:onConfigValidationError():addAction(function()
            addon_system_error("You must choose 5 different songs.")
        end), songConfigEditor:onConfigValidationError())

        songConfigEditor:setTitle("Choose 5 songs to sing.")
        songConfigEditor:setShouldRequestFocus(true)

        self.selectedSongIndex = 1

        return songConfigEditor
    end

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.selectedSongIndex = 1

    self:reloadSettings()

    return self
end

function SongListMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function SongListMenuItem:reloadSettings()
    self:setChildMenuItem("Jobs", self:getEditJobsMenuItem())
end

function SongListMenuItem:getEditJobsMenuItem()
    local editJobsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear All', 18),
    }, {}, function(_, _)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.Songs

        local configItem = MultiPickerConfigItem.new("Jobs", songs[self.selectedSongIndex]:get_job_names(), job_util.all_jobs(), function(jobNameShort)
            return i18n.resource('jobs', 'ens', jobNameShort)
        end, "Jobs")

        local jobsPickerView = FFXIPickerView.withConfig(L{ configItem }, true)

        self.disposeBag:add(jobsPickerView:on_pick_items():addAction(function(_, newJobNames)
            if self.selectedSongIndex and newJobNames:length() > 0 then
                local song = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.Songs[self.selectedSongIndex]
                song:set_job_names(newJobNames)

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll only keep this song on these jobs!")
            else
                addon_system_error("Choose one or more jobs.")
            end
        end), jobsPickerView:on_pick_items())

        return jobsPickerView
    end, "Songs", "Choose jobs to keep this song on.")
    return editJobsMenuItem
end

return SongListMenuItem