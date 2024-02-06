local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local CursorItem = setmetatable({}, {__index = ImageItem })
CursorItem.__index = CursorItem

function CursorItem.new()
    local self = setmetatable(ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24), CursorItem)
    return self
end

return CursorItem