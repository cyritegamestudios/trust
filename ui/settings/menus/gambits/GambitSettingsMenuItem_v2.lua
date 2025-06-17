local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIFastPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitLibraryMenuItem = require('ui/settings/menus/gambits/GambitLibraryMenuItem')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local ShortcutMenuItem = require('ui/settings/menus/ShortcutMenuItem')

local GambitConditionSettingsMenuItem = require('ui/settings/menus/gambits/GambitConditionSettingsMenuItem')

local GambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
GambitSettingsMenuItem.__index = GambitSettingsMenuItem

function GambitSettingsMenuItem:getGambits()
    return self.gambits
end

function GambitSettingsMenuItem:setGambits(gambits)
    self.gambits:setValue(gambits)
end

function GambitSettingsMenuItem.new(trustSettings, trustSettingsMode, settingsKey)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized("Edit", i18n.translate("Button_Edit"))
    }, {}, nil, "Gambits", "Edit Gambit settings."), GambitSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKey = settingsKey
    self.gambits = ValueRelay.new(L{})

    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, _, _)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, L{}, function(gambit, _)
            return gambit:tostring(), gambit:isValid() and gambit:isEnabled()
        end, "Gambits", nil, function(gambit)
            return AssetManager.imageItemForAbility(gambit:getAbility():get_name())
        end, function(gambit, _)
            if not gambit:isValid() then
                return "Unavailable on current job or settings."
            else
                return gambit:tostring()
            end
        end)
        self.gambitSettingsEditor = FFXIPickerView.withConfig(L{ configItem })
        self.gambitSettingsEditor:setAllowsCursorSelection(true)
        return self.gambitSettingsEditor
    end

    self.disposeBag:add(self.gambits:onValueChanged():addAction(function(_, newValue)
        if self.gambitSettingsEditor then
            self.gambitSettingsEditor:setConfigItems(L{ self:getConfigItems(newValue) })
        end
    end, self.gambits:onValueChanged()))

    return self
end

function GambitSettingsMenuItem:getSettings(mode)
    return self.trustSettings:getSettings()[mode or self.trustSettingsMode.value][self.settingsKey]
end

function GambitSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Edit", self:getEditGambitMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
    self:setChildMenuItem("Copy", self:getCopyGambitMenuItem())
    self:setChildMenuItem("Move Up", self:getMoveUpGambitMenuItem())
    self:setChildMenuItem("Move Down", self:getMoveDownGambitMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleMenuItem())
    self:setChildMenuItem("Reset", self:getResetGambitsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end


return GambitSettingsMenuItem