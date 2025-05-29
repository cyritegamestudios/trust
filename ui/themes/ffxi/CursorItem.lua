local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local CursorItem = setmetatable({}, {__index = ImageItem })
CursorItem.__index = CursorItem

function CursorItem.new(imageItem, offsetX, offsetY)
    imageItem = imageItem or ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)
    local self = setmetatable(imageItem, CursorItem)
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    return self
end

return CursorItem