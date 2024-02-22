local CursorItem = require('ui/themes/FFXI/CursorItem')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ScrollItem = require('ui/themes/FFXI/ScrollItem')

local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
local FFXIClassicStyle = setmetatable({}, {__index = CollectionViewStyle })
FFXIClassicStyle.__index = FFXIClassicStyle

FFXIClassicStyle.CenterImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_background.png',
        60,
        4
)

FFXIClassicStyle.Border = {}
FFXIClassicStyle.Border.LeftImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_border_left.png',
        20,
        3
)
FFXIClassicStyle.Border.CenterImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_border_middle.png',
        20,
        3
)
FFXIClassicStyle.Border.RightImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_border_right.png',
        20,
        3
)

function FFXIClassicStyle.default()
    local self = setmetatable(CollectionViewStyle.new(
            CursorItem.new(),
            ScrollItem.new(),
            FFXIClassicStyle.CenterImageItem,
            FFXIClassicStyle.Border.LeftImageItem,
            FFXIClassicStyle.Border.CenterImageItem,
            FFXIClassicStyle.Border.RightImageItem
    ), FFXIClassicStyle)
    return self
end

return FFXIClassicStyle