local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')

local FollowSettingsMenuItem = setmetatable({}, {__index = MenuItem })
FollowSettingsMenuItem.__index = FollowSettingsMenuItem

function FollowSettingsMenuItem.new(follower, addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Following", "Configure follow settings."), FollowSettingsMenuItem)

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
            ConfigItem.new('distance', 1, 18, 1, function(value) return value.." yalms" end),
        }
        return ConfigEditor.new(self.addonSettings, self.addonSettings:getSettings().follow, configItems)
    end, "Following", "Configure follow settings.")
    return configMenuItem
end

function FollowSettingsMenuItem:getModesMenuItem()
    local curesModesMenuItem = MenuItem.new(L{}, L{}, function(_)
        local modesView = ModesView.new(L{'AutoFollowMode', 'IpcMode'})
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for following.")
        return modesView
    end, "Modes", "Set modes for following.")
    return curesModesMenuItem
end

return FollowSettingsMenuItem