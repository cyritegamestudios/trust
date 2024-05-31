local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local MenuItem = require('cylibs/ui/menu/menu_item')
local WidgetSettingsMenuItem = require('ui/settings/menus/widgets/WidgetSettingsMenuItem')

local ConfigSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ConfigSettingsMenuItem.__index = ConfigSettingsMenuItem

function ConfigSettingsMenuItem.new(addonSettings, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Widgets', 18),
    }, {}, nil, "Config", "Change Trust's options."), ConfigSettingsMenuItem)

    self:reloadSettings(addonSettings, viewFactory)

    return self
end

function ConfigSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function ConfigSettingsMenuItem:reloadSettings(addonSettings, viewFactory)
    self:setChildMenuItem("Widgets", WidgetSettingsMenuItem.new(addonSettings, viewFactory))
end

return ConfigSettingsMenuItem