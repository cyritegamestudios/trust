local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local WidgetSettingsMenuItem = require('ui/settings/menus/widgets/WidgetSettingsMenuItem')

local ConfigSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConfigSettingsMenuItem.__index = ConfigSettingsMenuItem

function ConfigSettingsMenuItem.new(addonSettings, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Widgets', 18),
        ButtonItem.default('Logging', 18),
    }, {}, nil, "Config", "Change Trust's options."), ConfigSettingsMenuItem)

    self:reloadSettings(addonSettings, viewFactory)

    return self
end

function ConfigSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function ConfigSettingsMenuItem:reloadSettings(addonSettings, viewFactory)
    self:setChildMenuItem("Widgets", WidgetSettingsMenuItem.new(addonSettings, viewFactory))
    self:setChildMenuItem("Logging", self:getLoggingMenuItem(addonSettings))
end

function ConfigSettingsMenuItem:getLoggingMenuItem(addonSettings)
    local loggingMenuItem = MenuItem.new(L{
        ButtonItem.default('Save')
    }, L{
        Save = MenuItem.action(function()
            logger.isEnabled = addonSettings:getSettings().logging.enabled
            _libs.logger.settings.logtofile = addonSettings:getSettings().logging.logtofile
        end, "Logging", "Configure debug logging.")
    }, function(menuArgs)
        local configItems = L{
            BooleanConfigItem.new('enabled', "Enable Logging"),
            BooleanConfigItem.new('logtofile', "Log to File"),
        }
        return ConfigEditor.new(addonSettings, addonSettings:getSettings()[("logging"):lower()], configItems)
    end, "Logging", "Configure debug logging.")
    return loggingMenuItem
end

return ConfigSettingsMenuItem