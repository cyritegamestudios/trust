local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local RollSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RollSettingsMenuItem.__index = RollSettingsMenuItem

function RollSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.localized("Modes", i18n.translate("Modes")),
        ButtonItem.localized("Gambits", i18n.translate("Button_Gambits")),
    }, {
    }, nil, "Rolls", "Configure settings for Phantom Roll."), RollSettingsMenuItem)

    self.all_rolls = trust:get_job():get_all_rolls():sort()
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.trust = trust
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, _)
        local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].RollSettings

        local rollSettings = T{
            Roll1 = allSettings.Roll1:get_roll_name(),
            Roll2 = allSettings.Roll2:get_roll_name(),
            DoubleUpThreshold = allSettings.DoubleUpThreshold,
            NumRequiredPartyMembers = allSettings.NumRequiredPartyMembers
        }

        local configItems = L{
            PickerConfigItem.new('Roll1', rollSettings.Roll1, trust:get_job():get_all_rolls():sort(), nil, "Roll 1 (Crooked Cards)"),
            PickerConfigItem.new('Roll2', rollSettings.Roll2, trust:get_job():get_all_rolls():sort(), nil, "Roll 2"),
            ConfigItem.new('DoubleUpThreshold', 1, 10, 1, function(value) return value.."" end, "Double-Up Max"),
            ConfigItem.new('NumRequiredPartyMembers', 1, 6, 1, function(value) return value.."" end, "Num Party Members Nearby"),
        }

        local rollConfigEditor = ConfigEditor.new(self.trustSettings, rollSettings, configItems)

        self.dispose_bag:add(rollConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            if newSettings.Roll1 ~= newSettings.Roll2 then
                allSettings.Roll1 = Roll.new(newSettings.Roll1, true)
                allSettings.Roll2 = Roll.new(newSettings.Roll2, false)
                allSettings.DoubleUpThreshold = newSettings.DoubleUpThreshold
                allSettings.NumRequiredPartyMembers = newSettings.NumRequiredPartyMembers

                self.trustSettings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll use "..newSettings.Roll1.." and "..newSettings.Roll2.." now!")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't use the same roll twice!")
            end
        end), rollConfigEditor:onConfigChanged())

        return rollConfigEditor
    end

    self:reloadSettings()

    self.dispose_bag:add(trustSettingsMode:on_state_change():addAction(function(_, newValue)
        self:reloadSettings()
    end, trustSettingsMode:on_state_change()))

    return self
end

function RollSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function RollSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Modes", self:getModesMenuItem())
    self:setChildMenuItem("Gambits", self:getGambitsMenuItem())
end

function RollSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for rolls.", L{'AutoRollMode'})
end

function RollSettingsMenuItem:getGambitsMenuItem()
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

        local currentGambits = roller_gambits

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

        self.dispose_bag:add(gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            if selectedGambit then
                infoView:setDescription(selectedGambit:tostring())
            end
        end), gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        self.dispose_bag:add(gambitSettingsEditor:on_pick_items():addAction(function(_, selectedGambits)
            local roller = self.trust:role_with_type("roller")
            for gambit in selectedGambits:it() do
                local is_satisfied, target = roller:is_gambit_satisfied(gambit)
                if is_satisfied then
                    addon_system_message(string.format("%s satisified for %s.", gambit:tostring(), target:get_name()))
                else
                    addon_system_error(string.format("%s not satisified.", gambit:tostring()))
                    logger.error(string.format("%s not satisified.", gambit:tostring()))
                end
            end
        end), gambitSettingsEditor:on_pick_items())

        return gambitSettingsEditor
    end, "Rolling", "Roll gambits")
    return gambitsMenuItem
end

return RollSettingsMenuItem