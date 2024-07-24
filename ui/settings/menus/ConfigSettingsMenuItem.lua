local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
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

return ConfigSettingsMenuItem