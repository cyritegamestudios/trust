local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')

local FollowSettingsMenuItem = setmetatable({}, {__index = MenuItem })
FollowSettingsMenuItem.__index = FollowSettingsMenuItem

function FollowSettingsMenuItem.new(follower, trustModeSettings, addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Config', 18),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }, {}, nil, "Following", "Configure follow settings."), FollowSettingsMenuItem)

    self.trustModeSettings = trustModeSettings
    self.addonSettings = addonSettings
    self.follower = follower

    self:reloadSettings()

    return self
end

function FollowSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function FollowSettingsMenuItem:getConfigMenuItem()
    local configMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Reset', 18),
    }, L{}, function(menuArgs)
        local configItems = L{
            ConfigItem.new('distance', 1, 18, 1, function(value) return value.." yalms" end, "Follow Distance"),
        }
        return ConfigEditor.new(self.addonSettings, self.addonSettings:getSettings().follow, configItems)
    end, "Following", "Configure follow settings.")
    return configMenuItem
end

function FollowSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for following.",
            L{'AutoFollowMode', 'IpcMode'})
end

return FollowSettingsMenuItem