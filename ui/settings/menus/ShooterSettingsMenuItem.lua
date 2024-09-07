local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')

local ShooterSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ShooterSettingsMenuItem.__index = ShooterSettingsMenuItem

function ShooterSettingsMenuItem.new(trustSettings, trustSettingsMode, shooter)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Shooting", "Configure shooting settings."), ShooterSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
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
            ConfigItem.new('Delay', 1.5, 10, 0.5, function(value) return value.."s" end, "Shoot Delay"),
        }
        return ConfigEditor.new(self.trustSettings, shooterSettings, configItems)
    end, "Shooting", "Configure shooting settings.")
    return configMenuItem
end

function ShooterSettingsMenuItem:getModesMenuItem()
    local curesModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoShootMode', 'AutoSkillchainMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for shooting.")
        return modesView
    end, "Modes", "Set modes for shooting.")
    return curesModesMenuItem
end

return ShooterSettingsMenuItem