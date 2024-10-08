local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local RemoteCommandsSettingsMenuItem = require('ui/settings/menus/RemoteCommandsSettingsMenuItem')
local WidgetSettingsMenuItem = require('ui/settings/menus/widgets/WidgetSettingsMenuItem')

local ConfigSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConfigSettingsMenuItem.__index = ConfigSettingsMenuItem

function ConfigSettingsMenuItem.new(addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Widgets', 18),
        ButtonItem.default('Logging', 18),
        ButtonItem.default('Remote', 18),
        ButtonItem.default('Language', 18),
    }, {}, nil, "Config", "Change Trust's options."), ConfigSettingsMenuItem)

    self:reloadSettings(addonSettings)

    return self
end

function ConfigSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function ConfigSettingsMenuItem:reloadSettings(addonSettings)
    self:setChildMenuItem("Widgets", WidgetSettingsMenuItem.new(addonSettings))
    self:setChildMenuItem("Logging", self:getLoggingMenuItem(addonSettings))
    self:setChildMenuItem("Remote", RemoteCommandsSettingsMenuItem.new(addonSettings))
    self:setChildMenuItem("Language", self:getLanguageSettingsMenuItem(addonSettings))
end

function ConfigSettingsMenuItem:getLoggingMenuItem(addonSettings)
    local filterMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
        ButtonItem.default('Clear'),
    }, {
        Clear = MenuItem.action(function()
            logger.filterPattern = nil
        end, "Logging", "Clear log filter.")
    }, function(menuArgs, infoView)
        local setFilterView = FFXITextInputView.new('', "Log filter")
        setFilterView:setTitle("Filter logs by pattern.")
        setFilterView:setShouldRequestFocus(true)
        setFilterView:onTextChanged():addAction(function(_, filterPattern)
            if filterPattern:length() > 1 then
                logger.filterPattern = filterPattern
            end
        end)
        return setFilterView
    end, "Logging", "Filter logs.")

    local loggingMenuItem = MenuItem.new(L{
        ButtonItem.default('Save'),
        ButtonItem.default('Filter')
    }, {
        Save = MenuItem.action(function()
            logger.isEnabled = addonSettings:getSettings().logging.enabled
            _libs.logger.settings.logtofile = addonSettings:getSettings().logging.logtofile
        end, "Logging", "Configure debug logging."),
        Filter = filterMenuItem,
    }, function(menuArgs)
        local configItems = L{
            BooleanConfigItem.new('enabled', "Enable Logging"),
            BooleanConfigItem.new('logtofile', "Log to File"),
        }
        return ConfigEditor.new(addonSettings, addonSettings:getSettings()[("logging"):lower()], configItems)
    end, "Logging", "Configure debug logging.")
    return loggingMenuItem
end

function ConfigSettingsMenuItem:getLanguageSettingsMenuItem(addonSettings)
    local languageMenuItem = MenuItem.new(L{
        ButtonItem.default('Save'),
    }, {
        Save = MenuItem.action(function()
            localization_util.set_should_use_client_locale(addonSettings:getSettings().locales.actions.use_client_locale)
        end),
    }, function(menuArgs)
        local configItems = L{
            BooleanConfigItem.new('use_client_locale', "Use client langauge for actions"),
        }
        return ConfigEditor.new(addonSettings, addonSettings:getSettings().locales.actions, configItems)
    end, "Language", "Configure language settings.")
    return languageMenuItem
end

return ConfigSettingsMenuItem