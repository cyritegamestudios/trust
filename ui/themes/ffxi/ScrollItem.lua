local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local ScrollItem = setmetatable({}, {__index = ResizableImageItem })
ScrollItem.__index = ScrollItem

function ScrollItem.new()
    local self = setmetatable(ResizableImageItem.new(
            ImageItem.new(windower.addon_path..'assets/icons/icon_scroll_arrow_up.png', 8, 4),
            nil,
            ImageItem.new(windower.addon_path..'assets/icons/icon_scroll_arrow_down.png', 8, 4),
            nil,
            ImageItem.new(windower.addon_path..'assets/backgrounds/scroll_track.png', 8, 64)
    ), ScrollItem)
    return self
end

return ScrollItem