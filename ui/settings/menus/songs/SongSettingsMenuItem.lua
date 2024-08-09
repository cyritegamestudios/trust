local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local SongPickerView = require('ui/settings/pickers/SongPickerView')
local SongSettingsEditor = require('ui/settings/SongSettingsEditor')
local SongValidator = require('cylibs/entity/jobs/bard/song_validator')

local SongSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SongSettingsMenuItem.__index = SongSettingsMenuItem

function SongSettingsMenuItem.new(addonSettings, trustSettings, trustSettingsMode, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Diagnostics', 18),
        ButtonItem.default('Help', 18),
    }, {},
    function()
        local songSettingsView = SongSettingsEditor.new(trustSettings, trustSettingsMode, addonSettings:getSettings().help.wiki_base_url..'/Singer')
        songSettingsView:setShouldRequestFocus(true)
        songSettingsView:setAllowsCursorSelection(true)
        return songSettingsView
    end, "Songs", "Choose songs to sing."), SongSettingsMenuItem)

    self.addonSettings = addonSettings
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.songSettings = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings
    self.songValidator = SongValidator.new(trust:role_with_type("singer"), action_queue)
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function SongSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function SongSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Edit", self:getEditMenuItem())
    --self:setChildMenuItem("Move Up", MenuItem.new(L{}, {}, nil))
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Diagnostics", self:getDiagnosticsMenuItem())
    self:setChildMenuItem("Help", MenuItem.action(function()
        windower.open_url(self.addonSettings:getSettings().help.wiki_base_url..'/Singer')
    end))
end

function SongSettingsMenuItem:getEditMenuItem()
    local editSongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
    function(args)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.Songs

        local allSongs = spell_util.get_spells(function(spell)
            return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en  end)

        local chooseSongsView = SongPickerView.new(self.trustSettings, songs, allSongs, function(songNames)
            return self:validateSongs(songNames)
        end)
        chooseSongsView:setTitle("Choose 5 songs to sing.")
        chooseSongsView:setShouldRequestFocus(true)
        return chooseSongsView
    end, "Songs", "Choose 5 songs to sing.")

    local editDummySongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
    function(args)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.DummySongs

        local allSongs = spell_util.get_spells(function(spell)
            return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en  end)

        local chooseSongsView = SongPickerView.new(self.trustSettings, songs, allSongs, function(songNames)
            return self:validateDummySongs(songNames)
        end)
        chooseSongsView:setTitle("Choose 3 dummy songs to sing.")
        chooseSongsView:setShouldRequestFocus(true)
        return chooseSongsView
    end, "Songs", "Choose 3 dummy songs to sing.")

    local songTypeMenuItem = MenuItem.new(L{
        ButtonItem.default('Songs', 18),
        ButtonItem.default('Dummy', 18),
        ButtonItem.default('Pianissimo', 18),
    }, {
        Songs = editSongsMenuItem,
        Dummy = editDummySongsMenuItem,
        Pianissimo = self:getPianissmoSongsMenuItem(),
    }, nil, "Songs", "Choose dummy songs and songs to sing.")

    return songTypeMenuItem
end

function SongSettingsMenuItem:getPianissmoSongsMenuItem()
    local imageItemForText = function(text)
        return AssetManager.imageItemForSpell(text)
    end

    local addPianissimoSongMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {}, function(_, _)
        local allSongs = spell_util.get_spells(function(spell)
            return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en end)

        local chooseSongsView = FFXIPickerView.withItems(allSongs, L{}, true, nil, imageItemForText)

        chooseSongsView:setTitle("Choose pianissimo songs.")
        chooseSongsView:setShouldRequestFocus(true)

        self.dispose_bag:add(chooseSongsView:on_pick_items():addAction(function(_, selectedItems)
            if selectedItems:length() > 0 then
                local newSongs = selectedItems:map(function(item)
                    return Spell.new(item:getText(), L{ 'Pianissimo' })
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
    }, function(_, _)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings.PianissimoSongs

        local pianissimoSongsView = FFXIPickerView.withItems(songs:map(function(song) return song:get_spell().en end), L{}, false, nil, imageItemForText)

        pianissimoSongsView:setShouldRequestFocus(true)
        pianissimoSongsView:setAllowsCursorSelection(true)

        self.dispose_bag:add(pianissimoSongsView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedPianissimoSongIndex = indexPath.row
        end), pianissimoSongsView:getDelegate():didSelectItemAtIndexPath())

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
            function()
                local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

                local songSettings = T{
                    NumSongs = allSettings.SongSettings.NumSongs,
                    SongDuration = allSettings.SongSettings.SongDuration,
                    SongDelay = allSettings.SongSettings.SongDelay
                }

                local configItems = L{
                    ConfigItem.new('NumSongs', 2, 4, 1, function(value) return value.."" end, "Maximum Number of Songs"),
                    ConfigItem.new('SongDuration', 120, 400, 10, function(value) return value.."s" end, "Song Duration"),
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

                return songConfigEditor
            end, "Config", "Configure general song settings.")
    return songConfigMenuItem
end

function SongSettingsMenuItem:getDiagnosticsMenuItem()
    return MenuItem.action(function()
        self.songValidator:validate()
    end, "Songs", "Run diagnostics to debug issues with songs.")
end

function SongSettingsMenuItem:getModesMenuItem()
    local songModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoSongMode', 'AutoClarionCallMode', 'AutoNitroMode', 'AutoPianissimoMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for singing.")
        return modesView
    end, "Modes", "Change singing behavior.")
    return songModesMenuItem
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