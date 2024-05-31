local ToggleButtonItem = require('cylibs/ui/collection_view/items/toggle_button_item')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')

local FFXIToggleButtonItem = setmetatable({}, {__index = ToggleButtonItem })
FFXIToggleButtonItem.__index = FFXIToggleButtonItem

function FFXIToggleButtonItem.new()
    local enabledImageItem = ImageItem.new(windower.addon_path..'assets/buttons/toggle_button_on.png', 23, 14)
    local disabledImageItem = ImageItem.new(windower.addon_path..'assets/buttons/toggle_button_off.png', 23, 14)

    local buttonItem = ToggleButtonItem.new(enabledImageItem, disabledImageItem)
    return buttonItem
end

return FFXIToggleButtonItem