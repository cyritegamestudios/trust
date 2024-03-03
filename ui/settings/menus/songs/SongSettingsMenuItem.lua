local BloodPactSettingsEditor = require('ui/settings/editors/BloodPactSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CursorItem = require('ui/themes/FFXI/CursorItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local PickerView = require('cylibs/ui/picker/picker_view')
local SongPickerView = require('ui/settings/pickers/SongPickerView')
local SongSettingsEditor = require('ui/settings/SongSettingsEditor')

local SongSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SongSettingsMenuItem.__index = SongSettingsMenuItem

function SongSettingsMenuItem.new(addonSettings, trustSettings, trustSettingsMode, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Help', 18),
    }, {},
    function()
        local songSettingsView = viewFactory(SongSettingsEditor.new(trustSettings, trustSettingsMode, addonSettings:getSettings().help.wiki_base_url..'/Singer'))
        songSettingsView:setShouldRequestFocus(true)
        return songSettingsView
    end, "Songs", "Choose songs to sing."), SongSettingsMenuItem)

    self.addonSettings = addonSettings
    self.trustSettings = trustSettings
    self.songSettings = T(trustSettings:getSettings())[trustSettingsMode.value]
    self.viewFactory = viewFactory
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
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Help", MenuItem.action(function()
        windower.open_url(self.addonSettings:getSettings().help.wiki_base_url..'/Singer')
    end))
end

function SongSettingsMenuItem:getEditMenuItem()
    local editSongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
    function(args)
        local songs = self.songSettings.Songs

        local allSongs = spell_util.get_spells(function(spell)
            return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en  end)

        local chooseSongsView = self.viewFactory(SongPickerView.new(self.trustSettings, songs, allSongs, function(songNames)
            return self:validateSongs(songNames)
        end))
        chooseSongsView:setTitle("Choose 5 songs to sing.")
        chooseSongsView:setShouldRequestFocus(true)
        return chooseSongsView
    end, "Songs", "Choose 5 songs to sing.")

    local editDummySongsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
    function(args)
        local songs = self.songSettings.DummySongs

        local allSongs = spell_util.get_spells(function(spell)
            return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en  end)

        local chooseSongsView = self.viewFactory(SongPickerView.new(self.trustSettings, songs, allSongs, function(songNames)
            return self:validateDummySongs(songNames)
        end))
        chooseSongsView:setTitle("Choose 3 dummy songs to sing.")
        chooseSongsView:setShouldRequestFocus(true)
        return chooseSongsView
    end, "Songs", "Choose 3 dummy songs to sing.")

    local songTypeMenuItem = MenuItem.new(L{
        ButtonItem.default('Songs', 18),
        ButtonItem.default('Dummy', 18),
    }, {
        Songs = editSongsMenuItem,
        Dummy = editDummySongsMenuItem
    }, nil, "Songs", "Choose dummy songs and songs to sing.")

    return songTypeMenuItem
end

function SongSettingsMenuItem:getModesMenuItem()
    local geomancyModesMenuItem = MenuItem.new(L{}, L{}, function(_)
        local modesView = self.viewFactory(ModesView.new(L{'AutoSongMode', 'AutoClarionCallMode', 'AutoNitroMode', 'AutoPianissimoMode'}))
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for singing.")
        return modesView
    end, "Modes", "Change singing behavior.")
    return geomancyModesMenuItem
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