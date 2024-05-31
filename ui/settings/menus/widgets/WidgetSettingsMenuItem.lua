local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')

local WidgetSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WidgetSettingsMenuItem.__index = WidgetSettingsMenuItem

function WidgetSettingsMenuItem.new(addonSettings, viewFactory)
    local widgetNames = L{ 'Trust', 'Party', 'Target' }

    local buttonItems = widgetNames:map(function(widgetName)
        return ButtonItem.default(widgetName, 18)
    end)

    local self = setmetatable(MenuItem.new(buttonItems, {}, nil, "Widgets", "Configure widgets."), WidgetSettingsMenuItem)

    self.addonSettings = addonSettings
    self.viewFactory = viewFactory
    self.widgetNames = widgetNames
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function WidgetSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function WidgetSettingsMenuItem:reloadSettings()
    for widgetName in self.widgetNames:it() do
        self:setChildMenuItem(widgetName, self:getWidgetMenuItem(widgetName))
    end
end

function WidgetSettingsMenuItem:getWidgetMenuItem(widgetName)
    return MenuItem.new(L{
        ButtonItem.default('Save')
    }, L{}, function(menuArgs)
        local configItems = L{
            ConfigItem.new('x', 0, windower.get_windower_settings().ui_x_res, 1, function(value) return value.."" end),
            ConfigItem.new('y', 0, windower.get_windower_settings().ui_y_res, 1, function(value) return value.."" end),
            BooleanConfigItem.new('visible'),
        }
        return self.viewFactory(ConfigEditor.new(self.addonSettings, self.addonSettings:getSettings()[(widgetName.."_widget"):lower()], configItems))
    end, "Widgets", "Configure the "..widgetName.." widget. UI does not update until saved.")
end

return WidgetSettingsMenuItem