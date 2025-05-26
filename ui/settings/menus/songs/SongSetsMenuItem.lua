local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
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
        ButtonItem.default('Preview', 18),
        ButtonItem.localized("Modes", i18n.translate("Modes")),
        ButtonItem.localized("Gambits", i18n.translate("Button_Gambits"))
    }, {}, nil, "Song Sets", "Choose or edit a song set."), SongSetsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.selectedSetName = ValueRelay.new('Default')
    self.disposeBag = DisposeBag.new()

    local SongSettingsMenuItem = require('ui/settings/menus/songs/SongSettingsMenuItem')
    self.editSetMenuItem = SongSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, 'Default', trust)

    self.selectedSetName:onValueChanged():addAction(function(_, newValue)
        self.editSetMenuItem:setSongSetName(newValue)
    end)

    self:setChildMenuItem("Edit", self.editSetMenuItem)

    self.contentViewConstructor = function(_, _)
        local songSets = trustSettings:getSettings()[trustSettingsMode.value].SongSettings.SongSets
        local songSetNames = L(T(songSets):keyset()):sort()

        local configItem = MultiPickerConfigItem.new("SongSets", L{ state.SongSet.value }, songSetNames, function(value)
            return tostring(value)
        end, "Song Sets", nil, function(_)
            return AssetManager.imageItemForSpell("Mage's Ballad")
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
                addon_system_error("---== WARNING ==---- switching song sets with existing songs may cause a sing loop.")
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
    self:setChildMenuItem("Preview", self:getPreviewSetMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Gambits", self:getGambitsMenuItem())
end

function SongSetsMenuItem:getGambitsMenuItem()
    local gambitsMenuItem = MenuItem.new(L{
        ButtonItem.default("Confirm")
    }, {}, function(_, infoView)
        local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
        local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
        local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
        local IndexedItem = require('cylibs/ui/collection_view/indexed_item')

        local editorConfig = GambitEditorStyle.new(function(gambits)
            local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit)
                return gambit:tostring()
            end)
            return configItem
        end, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, "Gambit", "Gambits")

        local currentGambits = singer_gambits

        local configItem = editorConfig:getConfigItem(currentGambits)

        local gambitSettingsEditor = FFXIPickerView.new(L{ configItem }, false, editorConfig:getViewSize())
        gambitSettingsEditor:setAllowsCursorSelection(true)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        local itemsToUpdate = L{}
        for rowIndex = 1, gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) do
            local indexPath = IndexPath.new(1, rowIndex)
            local item = gambitSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            item:setEnabled(currentGambits[rowIndex]:isEnabled() and currentGambits[rowIndex]:isValid())
            itemsToUpdate:append(IndexedItem.new(item, indexPath))
        end

        gambitSettingsEditor:getDataSource():updateItems(itemsToUpdate)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            if selectedGambit then
                infoView:setDescription(selectedGambit:tostring())
            end
        end), gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        self.disposeBag:add(gambitSettingsEditor:on_pick_items():addAction(function(_, selectedGambits)
            local singer = self.trust:role_with_type("singer")
            for gambit in selectedGambits:it() do
                local is_satisfied, target = singer:is_gambit_satisfied(gambit)
                if is_satisfied then
                    addon_system_message(string.format("%s satisified for %s.", gambit:tostring(), target:get_name()))
                else
                    addon_system_error(string.format("%s not satisified.", gambit:tostring()))
                    logger.error(string.format("%s not satisified.", gambit:tostring()))
                end
            end
        end), gambitSettingsEditor:on_pick_items())

        return gambitSettingsEditor
    end, "Gambits", "Song gambits")
    return gambitsMenuItem
end

function SongSetsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
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

function SongSetsMenuItem:getPreviewSetMenuItem()
    local previewMenuItem = MenuItem.new(L{
        ButtonItem.default('Help', 18),
    }, {
        Help = MenuItem.action(function()
            windower.open_url(windower.trust.settings.get_addon_settings():getSettings().help.wiki_base_url..'/Singer')
        end)
    }, function(_, _)
        local SongListView = require('ui/views/SongListView')
        local singer = self.trust:role_with_type("singer")
        local songListView = SongListView.new(singer)
        return songListView
    end, "Songs", "View the merged list of songs for each job. May vary depending upon song duration.")
    return previewMenuItem
end

function SongSetsMenuItem:getConfigMenuItem()
    local songConfigMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {},
            function(_, infoView)
                local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

                local songSettings = T{
                    ResingDuration = allSettings.SongSettings.ResingDuration or 75,
                    ResingMissingSongs = allSettings.SongSettings.ResingMissingSongs or false,
                    DummySongThreshold = allSettings.SongSettings.DummySongThreshold or 2,
                }

                local configItems = L{
                    ConfigItem.new('ResingDuration', 60, 180, 1, function(value) return value.."s" end, "Resing Threshold"),
                    BooleanConfigItem.new('ResingMissingSongs', "Resing Missing Songs"),
                    ConfigItem.new('DummySongThreshold', 2, 4, 1, function(value) return value end, "Dummy Song Threshold"),
                }

                local songConfigEditor = ConfigEditor.new(self.trustSettings, songSettings, configItems, infoView, function(newSettings)
                    return true
                end)

                songConfigEditor:setTitle('Configure general song settings.')
                songConfigEditor:setShouldRequestFocus(true)

                self.disposeBag:add(songConfigEditor:onConfigChanged():addAction(function(newSettings, _)
                    if allSettings.SongSettings.DummySongThreshold ~= newSettings.DummySongThreshold then
                        addon_system_error("---== WARNING ==---- changing the dummy song threshold can completely break singing if you don't know what you are doing.")
                    end

                    allSettings.SongSettings.SongDuration = newSettings.SongDuration
                    allSettings.SongSettings.ResingDuration = newSettings.ResingDuration
                    allSettings.SongSettings.ResingMissingSongs = newSettings.ResingMissingSongs
                    allSettings.SongSettings.SongDelay = newSettings.SongDelay
                    allSettings.SongSettings.DummySongThreshold = newSettings.DummySongThreshold

                    self.trustSettings:saveSettings(true)
                end), songConfigEditor:onConfigChanged())

                self.disposeBag:add(songConfigEditor:onConfigValidationError():addAction(function()
                    addon_system_error("Unable to sing more than 2 songs without GearSwap enabled.")
                end), songConfigEditor:onConfigValidationError())

                self.disposeBag:add(songConfigEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
                    local currentSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

                    if indexPath.section == 1 then
                        infoView:setDescription("Resing all songs when any song has less than "..currentSettings.SongSettings.ResingDuration.."s remaining.")
                    elseif indexPath.section == 2 then
                        infoView:setDescription("Resing missing songs onto party members using Pianissimo.")
                    elseif indexPath.section == 3 then
                        infoView:setDescription(string.format("Sing dummy songs after the target has %d songs.", currentSettings.SongSettings.DummySongThreshold))
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
            L{'AutoSongMode', 'AutoClarionCallMode', 'AutoNitroMode', 'AutoPianissimoMode', 'SongSet'})
end

function SongSetsMenuItem:getSelectedSetName()
    return self.songListEditor
end

return SongSetsMenuItem