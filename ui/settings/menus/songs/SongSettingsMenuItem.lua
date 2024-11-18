local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SongListMenuItem = require('ui/settings/menus/songs/SongListMenuItem')
local SongListView = require('ui/views/SongListView')
local SongSettingsEditor = require('ui/settings/SongSettingsEditor')
local SongValidator = require('cylibs/entity/jobs/bard/song_validator')

local SongSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SongSettingsMenuItem.__index = SongSettingsMenuItem

function SongSettingsMenuItem.new(addonSettings, trustSettings, trustSettingsMode, trustModeSettings, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Preview', 18),
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Help', 18),
    }, {},
    function(_, _, _, _)
        local songSettingsView = SongSettingsEditor.new(trustSettings, trustSettingsMode, addonSettings:getSettings().help.wiki_base_url..'/Singer')
        songSettingsView:setShouldRequestFocus(true)
        return songSettingsView
    end, "Songs", "Choose songs to sing."), SongSettingsMenuItem)

    self.addonSettings = addonSettings
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.trust = trust
    self.songSettings = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings
    self.songValidator = SongValidator.new(trust:role_with_type("singer"), action_queue)
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function SongSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function SongSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Edit", self:getEditSongsMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Preview", self:getDiagnosticsMenuItem())
    self:setChildMenuItem("Help", MenuItem.action(function()
        windower.open_url(self.addonSettings:getSettings().help.wiki_base_url..'/Singer')
    end))
end

function SongSettingsMenuItem:getEditSongsMenuItem()
    local editSongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Dummy', 18),
        ButtonItem.default('Songs', 18),
        ButtonItem.default('Pianissimo', 18),
    }, {
        Dummy = self:getEditDummySongsMenuItem(),
        Songs = SongListMenuItem.new(self.trust, self.trustSettings, self.trustSettingsMode),
        Pianissimo = self:getPianissmoSongsMenuItem(),
    }, nil, "Songs", "Edit dummy songs, songs and pianissimo songs.")
    return editSongsMenuItem
end

function SongSettingsMenuItem:getEditDummySongsMenuItem()
    local editDummySongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
        function(_, infoView)
            local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.DummySongs

            local allSongs = self.trust:get_job():get_spells(function(spellId)
                local spell = res.spells[spellId]
                return spell and spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
            end):map(function(spellId) return res.spells[spellId].en  end):sort()

            local songSettings = {
                Song1 = songs[1]:get_name(),
                Song2 = songs[2]:get_name(),
                Song3 = songs[3]:get_name()
            }

            local configItems = L{
                PickerConfigItem.new('Song1', songSettings.Song1, allSongs, nil, "Dummy Song 1"),
                PickerConfigItem.new('Song2', songSettings.Song2, allSongs, nil, "Dummy Song 2"),
                PickerConfigItem.new('Song3', songSettings.Song3, allSongs, nil, "Dummy Song 3"),
            }

            local songConfigEditor = ConfigEditor.new(nil, songSettings, configItems, infoView, function(newSettings)
                local newSongNames = L{}
                for _, songName in pairs(newSettings) do
                    newSongNames:append(songName)
                end
                if S(newSongNames):length() ~= 3 then
                    return false
                end
                return true
            end)

            songConfigEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
                local dummySongs = L{
                    Spell.new(newSettings.Song1),
                    Spell.new(newSettings.Song2),
                    Spell.new(newSettings.Song3),
                }

                local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.DummySongs
                songs:clear()
                songs = songs:extend(dummySongs)

                self.trustSettings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my dummy songs!")
            end)

            songConfigEditor:onConfigValidationError():addAction(function()
                addon_system_error("You must choose 3 different dummy songs.")
            end)

            songConfigEditor:setTitle("Choose 3 dummy songs to sing.")
            songConfigEditor:setShouldRequestFocus(true)

            return songConfigEditor
        end, "Dummy", "Choose 3 dummy songs to sing.")
    return editDummySongsMenuItem
end

function SongSettingsMenuItem:getPianissmoSongsMenuItem()
    local imageItemForText = function(text)
        return AssetManager.imageItemForSpell(text)
    end

    local addPianissimoSongMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {}, function(_, _)
        local allSongs = self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spellId) return res.spells[spellId].en  end):sort()

        local chooseSongsView = FFXIPickerView.withItems(allSongs, L{}, true, nil, imageItemForText)

        chooseSongsView:setTitle("Choose pianissimo songs.")
        chooseSongsView:setShouldRequestFocus(true)

        self.dispose_bag:add(chooseSongsView:on_pick_items():addAction(function(_, selectedItems)
            if selectedItems:length() > 0 then
                local newSongs = selectedItems:map(function(item)
                    return Spell.new(item:getText(), L{ 'Pianissimo' }, L{})
                end):compact_map()

                local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.PianissimoSongs
                songs = songs:extend(newSongs)

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")
            end
        end), chooseSongsView:on_pick_items())

        return chooseSongsView
    end, "Pianissimo", "Add a new pianissimo song.")

    local editJobsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_, _)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.PianissimoSongs

        local jobsPickerView = FFXIPickerView.withItems(job_util.all_jobs(), songs[self.selectedPianissimoSongIndex]:get_job_names(), true)

        self.dispose_bag:add(jobsPickerView:on_pick_items():addAction(function(_, selectedItems)
            if selectedItems:length() > 0 then
                local newJobNames = selectedItems:map(function(item)
                    return item:getText()
                end):compact_map()

                local song = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.PianissimoSongs[self.selectedPianissimoSongIndex]

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
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.PianissimoSongs

        local pianissimoSongsView = FFXIPickerView.withItems(songs:map(function(song) return song:get_spell().en end), L{}, false, nil, imageItemForText)

        pianissimoSongsView:setShouldRequestFocus(true)
        pianissimoSongsView:setAllowsCursorSelection(true)

        self.dispose_bag:add(pianissimoSongsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedPianissimoSongIndex = indexPath.row
            local song = songs[self.selectedPianissimoSongIndex]
            if song then
                if song:get_job_names():length() > 0 then
                    infoView:setDescription("Use when: Ally job is "..localization_util.commas(song:get_job_names(), "or"))
                else
                    infoView:setDescription("Use when: Never (no jobs selected)")
                end
            end
        end), pianissimoSongsView:getDelegate():didSelectItemAtIndexPath())

        if pianissimoSongsView:getDataSource():numberOfItemsInSection(1) > 0 then
            pianissimoSongsView:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
        end

        return pianissimoSongsView
    end, "Pianissimo", "Choose pianissimo songs.")

    editPianissimoSongsMenuItem:setChildMenuItem("Remove", MenuItem.action(function(menu)
        if self.selectedPianissimoSongIndex then
            local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.PianissimoSongs
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

function SongSettingsMenuItem:getConfigMenuItem()
    local songConfigMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function(_, infoView)
                local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

                local songSettings = T{
                    NumSongs = allSettings.SongSettings.NumSongs,
                    SongDuration = allSettings.SongSettings.SongDuration,
                    SongDelay = allSettings.SongSettings.SongDelay
                }

                local configItems = L{
                    ConfigItem.new('NumSongs', 2, 4, 1, function(value) return value.."" end, "Maximum Number of Songs"),
                    ConfigItem.new('SongDuration', 120, 400, 10, function(value) return value.."s" end, "Base Song Duration"),
                    ConfigItem.new('SongDelay', 4, 8, 1, function(value) return value.."s" end, "Delay Between Songs")
                }

                local songConfigEditor = ConfigEditor.new(self.trustSettings, songSettings, configItems)

                songConfigEditor:setTitle('Configure general song settings.')
                songConfigEditor:setShouldRequestFocus(true)

                self.dispose_bag:add(songConfigEditor:onConfigChanged():addAction(function(newSettings, _)
                    allSettings.SongSettings.NumSongs = newSettings.NumSongs
                    allSettings.SongSettings.SongDuration = newSettings.SongDuration
                    allSettings.SongSettings.SongDelay = newSettings.SongDelay

                    self.trustSettings:saveSettings(true)
                end), songConfigEditor:onConfigChanged())

                self.dispose_bag:add(songConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
                    if indexPath.section == 1 then
                        infoView:setDescription("Maximum number of songs without Clarion Call.")
                    elseif indexPath.section == 2 then
                        infoView:setDescription("Base song duration with gear but without Troubadour.")
                    else
                        infoView:setDescription("Configure general song settings.")
                    end
                end), songConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath())

                return songConfigEditor
            end, "Config", "Configure general song settings.")
    return songConfigMenuItem
end

function SongSettingsMenuItem:getDiagnosticsMenuItem()
    local diagnosticMenuItem = MenuItem.new(L{
        ButtonItem.default('Debug', 18),
    }, {
        Debug = MenuItem.action(function()
            self.songValidator:validate()
        end, "Songs", "Run diagnostics to debug issues with songs.")
    }, function(_, _)
        local singer = self.trust:role_with_type("singer")
        local songListView = SongListView.new(singer)
        return songListView
    end, "Songs", "View the merged list of songs for each job and run diagnostics.")
    return diagnosticMenuItem
end

function SongSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for singing.",
            L{'AutoSongMode', 'AutoClarionCallMode', 'AutoNitroMode', 'AutoPianissimoMode'})
end

function SongSettingsMenuItem:validateDummySongs(songNames)
    local buffsForDummySongs = S(songNames:map(function(songName)
        local spellId = spell_util.spell_id(songName)
        return buff_util.buff_for_spell(spellId).id
    end))
    if songNames:length() ~= 3 then
        return "You must choose 3 dummy songs."
    end
    local buffsForSongs = S(self.songSettings.Songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end))
    if set.intersection(buffsForDummySongs, buffsForSongs):length() > 0 then
        return "Dummy songs cannot give the same status effects as real songs."
    end
    return nil
end

function SongSettingsMenuItem:validateSongs(songNames)
    if songNames:length() ~= 5 then
        return "You must choose 5 songs."
    end
    return nil
end

return SongSettingsMenuItem