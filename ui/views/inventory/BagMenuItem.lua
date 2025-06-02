local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Item = require('resources/resources').Item
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')


local BagMenuItem = setmetatable({}, {__index = MenuItem })
BagMenuItem.__index = BagMenuItem

function BagMenuItem.new(bag)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_, infoView, _)
        local configItem = MultiPickerConfigItem.new("Items", L{}, bag:getItems():filter(function(item)
            return item.id ~= 0
        end), function(item)
            local matches = Item:where({ id = item.id }, L{ 'en', 'slots' })
            if matches:length() > 0 then
                return matches[1].en
            end
            return "Unknown"
        end)
        local bagView = FFXIPickerView.withConfig(configItem)
        bagView:setAllowsCursorSelection(true)
        return bagView
    end, bag:getName(), string.format("View items in %s.", bag:getName()), false), BagMenuItem)

    return self
end

return BagMenuItem