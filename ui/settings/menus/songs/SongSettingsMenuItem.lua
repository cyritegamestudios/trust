local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIFastPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SongListView = require('ui/views/SongListView')
local SongValidator = require('cylibs/entity/jobs/bard/song_validator')

local SongSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SongSettingsMenuItem.__index = SongSettingsMenuItem

function SongSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, songSetName, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Jobs'),
        ButtonItem.default('Pianissimo')
    }, {},
    nil, "Song Sets", "Edit songs in this set."), SongSettingsMenuItem)

    self.songSetName = songSetName
    self.selectedSongIndex = 1
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local songs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings.SongSets[self.songSetName].Songs
        local dummySongs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings.DummySongs

        local allSongs = trust:get_job():get_spells(function(spell_id)
            local spell = res.spells[spell_id]
            return spell and spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell_id)
            return res.spells[spell_id].en
        end):sort()

        local songSettings = {
            DummySong = dummySongs[1]:get_name(),
            Song1 = songs[1]:get_name(),
            Song2 = songs[2]:get_name(),
            Song3 = songs[3]:get_name(),
            Song4 = songs[4]:get_name(),
            Song5 = songs[5]:get_name()
        }

        local configItems = L{
            PickerConfigItem.new('DummySong', songSettings.DummySong, allSongs, nil, "Dummy Song"),
            PickerConfigItem.new('Song1', songSettings.Song1, allSongs, nil, "Song 1 (Marcato)"),
            PickerConfigItem.new('Song2', songSettings.Song2, allSongs, nil, "Song 2"),
            PickerConfigItem.new('Song3', songSettings.Song3, allSongs, nil, "Song 3"),
            PickerConfigItem.new('Song4', songSettings.Song4, allSongs, nil, "Song 4"),
            PickerConfigItem.new('Song5', songSettings.Song5, allSongs, nil, "Song 5"),
        }

        local songConfigEditor = ConfigEditor.new(nil, songSettings, configItems, infoView, function(newSettings)
            local newSongNames = L{}
            for key, songName in pairs(newSettings) do
                if key ~= 'DummySong' then
                    newSongNames:append(songName)
                end
            end
            local is_valid, error_message = trust:get_job():validate_songs(newSongNames, newSettings['DummySong'])
            return is_valid, error_message
        end)
        songConfigEditor:setShouldRequestFocus(true)

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
            local songs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings.SongSets[self.songSetName].Songs
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

            if newSettings["DummySong"] ~= oldSettings["DummySong"] then
                addon_system_error("Please update your GearSwap, e.g. sets.Midcast['"..newSettings["DummySong"].."'] = set_combine(sets.Nyame, {range='Daurdabla', ammo=empty})")
            end
            local dummySongs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings.DummySongs
            dummySongs:clear()

            local newSongName = newSettings["DummySong"]
            dummySongs:append(Spell.new(newSongName, L{}, L{}))

            trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")
        end), songConfigEditor:onConfigChanged())

        self.disposeBag:add(songConfigEditor:onConfigValidationError():addAction(function(errorMessage)
            errorMessage = errorMessage or "You must choose 5 different songs and a dummy song with a different buff than all songs."
            addon_system_error(errorMessage)
        end), songConfigEditor:onConfigValidationError())

        self.selectedSongIndex = 1

        return songConfigEditor
    end

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.trust = trust
    self.songSettings = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings
    self.songValidator = SongValidator.new(trust:role_with_type("singer"), action_queue)

    self:reloadSettings()

    return self
end

function SongSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function SongSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Jobs", self:getJobsMenuItem())
    self:setChildMenuItem("Pianissimo", self:getPianissmoSongsMenuItem())
    self:setChildMenuItem("Reset", self:getResetSongsMenuItem())
    self:setChildMenuItem("Help", MenuItem.action(function()
        windower.open_url(windower.trust.settings.get_addon_settings():getSettings().help.wiki_base_url..'/Singer')
    end))
end

function SongSettingsMenuItem:getJobsMenuItem()
    local editJobsMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Clear All'),
    }, {}, function(_, _)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName].Songs

        local configItem = MultiPickerConfigItem.new("Jobs", songs[self.selectedSongIndex-1]:get_job_names(), job_util.all_jobs(), function(jobNameShort)
            return i18n.resource('jobs', 'ens', jobNameShort)
        end)

        local jobsPickerView = FFXIPickerView.withConfig(configItem, true)

        self.disposeBag:add(jobsPickerView:on_pick_items():addAction(function(_, newJobNames)
            if newJobNames:length() > 0 then
                local song = songs[self.selectedSongIndex-1]

                local jobNames = song:get_job_names()
                jobNames:clear()

                for jobName in newJobNames:it() do
                    jobNames:append(jobName)
                end

                self.trustSettings:saveSettings(true)
                addon_system_message("Updated jobs for "..song:get_localized_name()..".")
            end
        end), jobsPickerView:on_pick_items())

        return jobsPickerView
    end, "Songs", "Choose jobs to maintain this song on.")

    editJobsMenuItem.enabled = function()
        return self.selectedSongIndex > 1
    end

    return editJobsMenuItem
end

function SongSettingsMenuItem:getPianissmoSongsMenuItem()
    local addPianissimoSongMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {}, function(_, _)
        local allSongs = self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spellId) return Spell.new(res.spells[spellId].en) end)

        local configItem = MultiPickerConfigItem.new("Pianissimo", L{}, allSongs, function(spell)
            return spell:get_localized_name()
        end, "Pianissimo", nil, function(spell)
            return AssetManager.imageItemForSpell(spell:get_name())
        end)

        local chooseSongsView = FFXIFastPickerView.new(configItem)

        self.disposeBag:add(chooseSongsView:on_pick_items():addAction(function(_, selectedSongs)
            if selectedSongs:length() > 0 then
                local newSongs = selectedSongs:map(function(song)
                    return Spell.new(song:get_name(), L{ 'Pianissimo' }, L{})
                end):compact_map()

                local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName].PianissimoSongs
                songs = songs:extend(newSongs)

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")
            end
        end), chooseSongsView:on_pick_items())

        return chooseSongsView
    end, "Pianissimo", "Add a new pianissimo song.")

    local editJobsMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Clear All'),
    }, {}, function(_, _)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName].PianissimoSongs

        local configItem = MultiPickerConfigItem.new("Jobs", songs[self.selectedPianissimoSongIndex]:get_job_names(), job_util.all_jobs(), function(jobNameShort)
            return i18n.resource('jobs', 'ens', jobNameShort)
        end)

        local jobsPickerView = FFXIPickerView.withConfig(configItem, true)

        self.disposeBag:add(jobsPickerView:on_pick_items():addAction(function(_, newJobNames)
            if newJobNames:length() > 0 then
                local song = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName].PianissimoSongs[self.selectedPianissimoSongIndex]

                local jobNames = song:get_job_names()
                jobNames:clear()

                for jobName in newJobNames:it() do
                    jobNames:append(jobName)
                end

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll only pianissimo this song on these jobs!")
            end
        end), jobsPickerView:on_pick_items())

        return jobsPickerView
    end, "Pianissimo", "Choose jobs to pianissimo this song on.")

    local editPianissimoSongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Add'),
        ButtonItem.default('Remove'),
        ButtonItem.default('Jobs'),
    }, {
        Add = addPianissimoSongMenuItem,
        Jobs = editJobsMenuItem,
    }, function(_, infoView)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName].PianissimoSongs

        local configItem = MultiPickerConfigItem.new("Pianissimo", L{}, songs, function(spell)
            return spell:get_localized_name()
        end, "Pianissimo", nil, function(spell)
            return AssetManager.imageItemForSpell(spell:get_name())
        end, function(song)
            if song:get_job_names():length() > 0 then
                return "Use when: Ally job is "..localization_util.commas(song:get_job_names(), "or")
            else
                return "Use when: Never (no jobs selected)"
            end
        end)

        local pianissimoSongsView = FFXIPickerView.withConfig(configItem)
        pianissimoSongsView:setAllowsCursorSelection(true)

        self.disposeBag:add(pianissimoSongsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedPianissimoSongIndex = indexPath.row
        end), pianissimoSongsView:getDelegate():didSelectItemAtIndexPath())

        if pianissimoSongsView:getDataSource():numberOfItemsInSection(1) > 0 then
            pianissimoSongsView:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
        end

        return pianissimoSongsView
    end, "Pianissimo", "Choose pianissimo songs.")

    editPianissimoSongsMenuItem:setChildMenuItem("Remove", MenuItem.action(function(menu)
        if self.selectedPianissimoSongIndex then
            local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName].PianissimoSongs
            songs:remove(self.selectedPianissimoSongIndex)

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")

            self.selectedPianissimoSongIndex = nil

            menu:showMenu(editPianissimoSongsMenuItem)
        end
    end))

    addPianissimoSongMenuItem:setChildMenuItem("Confirm", MenuItem.action(function(menu)
        menu:showMenu(editPianissimoSongsMenuItem)
    end))

    return editPianissimoSongsMenuItem
end

function SongSettingsMenuItem:getResetSongsMenuItem()
    return MenuItem.action(function(menu)
        local defaultSettings = T(self.trustSettings:getDefaultSettings().Default):clone().SongSettings
        local defaultSongSet = defaultSettings.SongSets.Default
        if defaultSongSet then
            self.trustSettings:getSettings()[self.trustSettingsMode.value].SongSettings.SongSets[self.songSetName] = defaultSongSet
            self.trustSettings:getSettings()[self.trustSettingsMode.value].SongSettings.DummySongs = defaultSettings.DummySongs

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've reset "..self.songSetName.." to its factory settings!")

            menu:showMenu(self)
        end
    end, "Songs", "Reset to default songs.")
end

function SongSettingsMenuItem:getDiagnosticsMenuItem()
    local debugMenuItem = MenuItem.action(function()
        if not addon_enabled:getValue() then
            addon_system_error("Trust must be enabled to perform this action.")
            return
        end
        self.songValidator:validate()
    end, "Songs", "Run diagnostics to debug issues with songs.")
    local diagnosticMenuItem = MenuItem.new(L{
        ButtonItem.default('Help', 18),
    }, {
        --Debug = debugMenuItem
        Help = MenuItem.action(function()
            windower.open_url(windower.trust.settings.get_addon_settings():getSettings().help.wiki_base_url..'/Singer')
        end)
    }, function(_, _)
        local singer = self.trust:role_with_type("singer")
        local songListView = SongListView.new(singer)
        return songListView
    end, "Songs", "View the merged list of songs for each job.")
    return diagnosticMenuItem
end

function SongSettingsMenuItem:setSongSetName(songSetName)
    self.songSetName = songSetName
end

return SongSettingsMenuItem