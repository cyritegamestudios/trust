local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')

local CombatModeSettingsMenuItem = setmetatable({}, {__index = MenuItem })
CombatModeSettingsMenuItem.__index = CombatModeSettingsMenuItem

function CombatModeSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, combat_mode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Config', 18),
        ButtonItem.localized("Modes", i18n.translate("Modes")),
    }, {}, nil, "Combat", "Configure combat settings."), CombatModeSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.combat_mode = combat_mode

    self:reloadSettings()

    return self
end

function CombatModeSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function CombatModeSettingsMenuItem:getConfigMenuItem()
    local configMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Reset', 18),
    }, L{}, function(menuArgs)
        local combatSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].CombatSettings

        local configItems = L{
            ConfigItem.new('Distance', 1.0, 30.0, 0.1, function(value) return value.." yalms" end, "Combat Distance"),
            ConfigItem.new('EngageDistance', 5, 30, 1, function(value) return value.." yalms" end, "Engage Distance"),
            ConfigItem.new('MirrorDistance', 0.2, 10, 0.1, function(value) return value.." yalms" end, "Mirror Distance"),
        }
        return ConfigEditor.new(self.trustSettings, combatSettings, configItems)
    end, "Combat", "Configure combat settings.")
    
    return configMenuItem
end

function CombatModeSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for combat.",
            L{'CombatMode', 'AutoEngageMode'})
end

return CombatModeSettingsMenuItem