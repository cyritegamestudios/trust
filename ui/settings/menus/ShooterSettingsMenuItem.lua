local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')

local ShooterSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ShooterSettingsMenuItem.__index = ShooterSettingsMenuItem

function ShooterSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, shooter)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Shooting", "Configure shooting settings."), ShooterSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.shooter = shooter

    self:reloadSettings()

    return self
end

function ShooterSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function ShooterSettingsMenuItem:getConfigMenuItem()
    local configMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Reset', 18),
    }, L{}, function(menuArgs)
        local shooterSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].Shooter

        local configItems = L{
            ConfigItem.new('Delay', 0.0, 10, 0.5, function(value) return value.."s" end, "Shoot Delay"),
        }
        return ConfigEditor.new(self.trustSettings, shooterSettings, configItems)
    end, "Shooting", "Configure shooting settings.")
    return configMenuItem
end

function ShooterSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for shooting.",
            L{'AutoShootMode'})
end

return ShooterSettingsMenuItem