local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local Keyboard = require('cylibs/ui/input/keyboard')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local WidgetSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WidgetSettingsMenuItem.__index = WidgetSettingsMenuItem

function WidgetSettingsMenuItem.new(addonSettings)
    local widgetNames = L{ 'Trust', 'Party', 'Target' }

    local buttonItems = widgetNames:map(function(widgetName)
        return ButtonItem.default(widgetName, 18)
    end)

    local self = setmetatable(MenuItem.new(buttonItems, {}, nil, "Widgets", "Configure widgets."), WidgetSettingsMenuItem)

    self.addonSettings = addonSettings
    self.widgetNames = widgetNames
    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function WidgetSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function WidgetSettingsMenuItem:reloadSettings()
    for widgetName in self.widgetNames:it() do
        self:setChildMenuItem(widgetName, self:getWidgetMenuItem(widgetName))
    end
end

function WidgetSettingsMenuItem:getWidgetMenuItem(widgetName)
    local widgetMenuItem = MenuItem.new(L{
        ButtonItem.default('Save')
    }, {}, function(menuArgs)
        local configItems = L{
            ConfigItem.new('x', 0, windower.get_windower_settings().ui_x_res, 1, function(value) return value.."" end, "X"),
            ConfigItem.new('y', 0, windower.get_windower_settings().ui_y_res, 1, function(value) return value.."" end, "Y"),
            BooleanConfigItem.new('visible', "Show Widget"),
            BooleanConfigItem.new('detailed', "Show Detailed View"),
        }
        local configEditor = ConfigEditor.new(self.addonSettings, self.addonSettings:getSettings()[(widgetName.."_widget"):lower()], configItems)
        return configEditor
    end, "Widgets", "Configure the "..widgetName.." widget. UI does not update until saved.")

    local shortcutSettings = self.addonSettings:getSettings().shortcuts.widgets[widgetName:lower()]
    if shortcutSettings then
        local shortcutsMenuItem = MenuItem.new(L{
            ButtonItem.default('Save', 18),
        }, {},
                function(_, _)
                    local shortcutSettings = self.addonSettings:getSettings().shortcuts.widgets[widgetName:lower()]

                    local configItems = L{
                        BooleanConfigItem.new('enabled', "Keyboard Shortcut"),
                        PickerConfigItem.new('key', shortcutSettings.key or Keyboard.allKeys()[1], Keyboard.allKeys(), function(keyName)
                            return keyName
                        end, "Key"),
                        PickerConfigItem.new('flags', shortcutSettings.flags or Keyboard.allFlags()[1], Keyboard.allFlags(), function(flag)
                            return Keyboard.input():getFlag(flag)
                        end, "Secondary Key"),
                    }

                    local shortcutsEditor = ConfigEditor.new(self.addonSettings, shortcutSettings, configItems)

                    self.disposeBag:add(shortcutsEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
                        if oldSettings.key and oldSettings.flags then
                            Keyboard.input():unregisterKeybind(oldSettings.key, oldSettings.flags)
                        end
                        if newSettings.enabled and newSettings.key and newSettings.flags then
                            Keyboard.input():registerKeybind(newSettings.key, newSettings.flags, function(keybind, pressed)
                                self:openMenu(menuItem)
                            end)
                        end
                    end), shortcutsEditor:onConfigChanged())

                    return shortcutsEditor
                end, widgetMenuItem:getTitleText(), "Configure keyboard shortcuts to show this menu.")
        widgetMenuItem:setChildMenuItem('Shortcuts', shortcutsMenuItem)
    end

    return widgetMenuItem
end

return WidgetSettingsMenuItem