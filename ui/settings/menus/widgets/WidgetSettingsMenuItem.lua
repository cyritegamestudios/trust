local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local ShortcutMenuItem = require('ui/settings/menus/ShortcutMenuItem')

local WidgetSettingsMenuItem = setmetatable({}, {__index = MenuItem })
WidgetSettingsMenuItem.__index = WidgetSettingsMenuItem

function WidgetSettingsMenuItem.new()
    local widgetNames = L{ 'Trust', 'Party', 'Target', 'Pet', 'Job' }

    local buttonItems = L{ ButtonItem.localized('Layout', i18n.translate("Button_Widget_Layout")) } + widgetNames:map(function(widgetName)
        return ButtonItem.default(widgetName, 18)
    end)

    local self = setmetatable(MenuItem.new(buttonItems, {}, nil, "Widgets", "Configure widget settings."), WidgetSettingsMenuItem)

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
    self:setChildMenuItem("Layout", self:getLayoutMenuItem())
end

function WidgetSettingsMenuItem:getWidgetMenuItem(widgetName)
    local widgetMenuItem = MenuItem.new(L{
        ButtonItem.default('Save')
    }, {}, function(_, _, _)
        local widgetName = widgetName:lower()

        local configItems = L{
            ConfigItem.new('x', 0, windower.get_windower_settings().ui_x_res, 1, function(value) return value.."" end, "X"),
            ConfigItem.new('y', 0, windower.get_windower_settings().ui_y_res, 1, function(value) return value.."" end, "Y"),
        }
        local configEditor = ConfigEditor.fromModel(WidgetSettings:get({
            name = widgetName, user_id = windower.ffxi.get_player().id
        }), configItems)
        self.disposeBag:add(configEditor:onConfigChanged():addAction(function(newSettings, _)
            local widget = windower.trust.ui.get_widget(widgetName)
            widget:setPosition(newSettings.x, newSettings.y)
            widget:layoutIfNeeded()
        end), configEditor:onConfigChanged())
        return configEditor
    end, "Widgets", "Configure the "..widgetName.." widget. UI does not update until saved.")

    widgetMenuItem:setChildMenuItem('Shortcuts', ShortcutMenuItem.new(widgetName:lower(), widgetName.." widget"))

    return widgetMenuItem
end

function WidgetSettingsMenuItem:getLayoutMenuItem()
    local layoutMenuItem = MenuItem.new(L{
        ButtonItem.default('Save')
    }, {}, function(_, _, _)
        local allAlignments = L{ 'Left', 'Right' }

        local layoutSettings = {
            Alignment = allAlignments[1]
        }

        local configItems = L{
            PickerConfigItem.new('Alignment', layoutSettings.Alignment, allAlignments, function(alignment)
                return alignment
            end, "Alignment"),
        }
        local configEditor = ConfigEditor.new(nil, layoutSettings, configItems)

        self.disposeBag:add(configEditor:onConfigChanged():addAction(function(newSettings, _)
            local yPos = windower.get_windower_settings().ui_y_res / 2 - 75

            for widgetName in L{ 'Trust', 'Party', 'Target' }:it() do
                local widget = windower.trust.ui.get_widget(widgetName)
                if widget then
                    local xPos
                    if newSettings.Alignment == 'Left' then
                        xPos = 16
                    else
                        xPos = windower.get_windower_settings().ui_x_res - widget:getSize().width - 16
                    end

                    widget:setEditing(true)
                    widget:setPosition(xPos, yPos)
                    widget:setEditing(false)
                    widget:layoutIfNeeded()

                    yPos = yPos + (widget:getMaxHeight() or widget:getSize().height) + 5
                end
            end
        end), configEditor:onConfigChanged())

        return configEditor
    end, "Widgets", "Group and arrange widgets on the screen.")
    return layoutMenuItem
end

return WidgetSettingsMenuItem