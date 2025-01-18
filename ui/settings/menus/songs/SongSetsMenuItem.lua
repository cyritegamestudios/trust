local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local ValueRelay = require('cylibs/events/value_relay')

local SongSetsMenuItem = setmetatable({}, {__index = MenuItem })
SongSetsMenuItem.__index = SongSetsMenuItem

function SongSetsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Create', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Delete', 18),
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Song Sets", "Choose or edit a song set."), SongSetsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.selectedSetName = ValueRelay.new('Default')
    self.disposeBag = DisposeBag.new()

    local SongSettingsMenuItem = require('ui/settings/menus/songs/SongSettingsMenuItem')
    self.editSetMenuItem = SongSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, 'Default', trust)

    self.selectedSetName:onValueChanged():addAction(function(_, newValue)
        self.editSetMenuItem:setSongSetName(newValue)
    end)

    self:setChildMenuItem("Edit", self.editSetMenuItem)

    self.contentViewConstructor = function(_, infoView)
        local songSets = trustSettings:getSettings()[trustSettingsMode.value].SongSettings.SongSets
        local songSetNames = L(T(songSets):keyset()):sort()

        local configItem = MultiPickerConfigItem.new("SongSets", L{ state.SongSet.value }, songSetNames, function(value)
            return tostring(value)
        end)

        local songListEditor = FFXIPickerView.withConfig(configItem)
        songListEditor:setAllowsCursorSelection(false)

        songListEditor:setNeedsLayout()
        songListEditor:layoutIfNeeded()

        self.disposeBag:add(songListEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local item = songListEditor:getDataSource():itemAtIndexPath(indexPath)
            if item then
                self.selectedSetName:setValue(item:getText() or 'Default')
            end
        end), songListEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        self.disposeBag:add(songListEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = songListEditor:getDataSource():itemAtIndexPath(indexPath)
            if item then
                state.SongSet:set(item:getText() or 'Default')
            end
        end), songListEditor:getDelegate():didSelectItemAtIndexPath())

        if songSets:length() > 0 then
            songListEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        self.songListEditor = songListEditor

        return songListEditor
    end

    self:reloadSettings()

    return self
end

function SongSetsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function SongSetsMenuItem:reloadSettings()
    self:setChildMenuItem("Create", self:getCreateSetMenuItem())
    self:setChildMenuItem("Delete", self:getDeleteSetMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function SongSetsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end)
    }, function(_)
        local configItems = L{
            TextInputConfigItem.new('SetName', 'NewSet', 'Set Name', function(_) return true  end)
        }

        local songSetConfigEditor = ConfigEditor.new(self.trustSettings, { SetName = '' }, configItems, nil, function(newSettings)
            local setName = newSettings.SetName
            if setName and setName:length() > 3 and setName:match("^[a-zA-Z]+$") ~= nil and not setName:find("%s") then
                return true
            end
            return false
        end)
        songSetConfigEditor:setShouldRequestFocus(true)

        self.disposeBag:add(songSetConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            local newSet = T(self.trustSettings:getDefaultSettings().Default):clone().SongSettings.SongSets.Default
            if newSet then
                local songSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].SongSettings.SongSets
                songSets[newSettings.SetName] = newSet

                self.trustSettings:saveSettings(true)

                addon_system_message("Created new song set named "..newSettings.SetName..".")
            end
        end), songSetConfigEditor:onConfigChanged())

        self.disposeBag:add(songSetConfigEditor:onConfigValidationError():addAction(function()
            addon_system_error("Song set names cannot contain spaces and must be at least 3 characters.")
        end), songSetConfigEditor:onConfigValidationError())

        return songSetConfigEditor
    end, "Song Sets", "Create a new song set.")
    return createSetMenuItem
end

function SongSetsMenuItem:getDeleteSetMenuItem()
    return MenuItem.action(function(menu)
        local songSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].SongSettings.SongSets
        if L(T(songSets):keyset()):length() <= 1 then
            addon_system_error("Unable to delete the last set.")
            return
        end

        songSets[self.selectedSetName:getValue()] = nil

        addon_system_message("Deleted song set named "..self.selectedSetName:getValue()..".")

        self.trustSettings:saveSettings(true)

        menu:showMenu(self)
    end, "Song Sets", "Delete the selected song set.", false, function()
        return self.selectedSetName:getValue() ~= nil and self.selectedSetName:getValue() ~= 'Default'
    end)
end

function SongSetsMenuItem:getConfigMenuItem()
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

                local songConfigEditor = ConfigEditor.new(self.trustSettings, songSettings, configItems, infoView, function(newSettings)
                    if newSettings.NumSongs > 2 and not allSettings.GearSwapSettings.Enabled then
                        return false
                    end
                    return true
                end)

                songConfigEditor:setTitle('Configure general song settings.')
                songConfigEditor:setShouldRequestFocus(true)

                self.disposeBag:add(songConfigEditor:onConfigChanged():addAction(function(newSettings, _)
                    allSettings.SongSettings.NumSongs = newSettings.NumSongs
                    allSettings.SongSettings.SongDuration = newSettings.SongDuration
                    allSettings.SongSettings.SongDelay = newSettings.SongDelay

                    self.trustSettings:saveSettings(true)
                end), songConfigEditor:onConfigChanged())

                self.disposeBag:add(songConfigEditor:onConfigValidationError():addAction(function()
                    addon_system_error("Unable to sing more than 2 songs without GearSwap enabled.")
                end), songConfigEditor:onConfigValidationError())

                self.disposeBag:add(songConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
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

function SongSetsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for singing.",
            L{'AutoSongMode', 'AutoClarionCallMode', 'AutoNitroMode', 'AutoPianissimoMode'})
end

function SongSetsMenuItem:getSelectedSetName()
    return self.songListEditor
end

return SongSetsMenuItem