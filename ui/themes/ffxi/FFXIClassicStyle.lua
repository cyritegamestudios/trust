local CursorItem = require('ui/themes/FFXI/CursorItem')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local Padding = require('cylibs/ui/style/padding')
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

FFXIClassicStyle.Padding = {}
FFXIClassicStyle.Padding.CollectionView = {}
FFXIClassicStyle.Padding.CollectionView.Default = Padding.new(8, 16, 8, 0)
FFXIClassicStyle.Padding.ConfigEditor = Padding.new(15, 16, 0, 0)

FFXIClassicStyle.WindowSize = {}
FFXIClassicStyle.WindowSize.Editor = {}
FFXIClassicStyle.WindowSize.Editor.Default = Frame.new(0, 0, 180, 192)
FFXIClassicStyle.WindowSize.Editor.ConfigEditor = Frame.new(0, 0, 350, 300)
FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge = Frame.new(0, 0, 500, 300)
FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge = Frame.new(0, 0, 600, 300)
FFXIClassicStyle.WindowSize.Picker = {}
FFXIClassicStyle.WindowSize.Picker.Wide = Frame.new(0, 0, 250, 192)
FFXIClassicStyle.WindowSize.Picker.ExtraLarge = Frame.new(0, 0, 275, 208)

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

function FFXIClassicStyle.background()
    local self = setmetatable(CollectionViewStyle.new(
            nil,
            ScrollItem.new(),
            FFXIClassicStyle.CenterImageItem,
            FFXIClassicStyle.Border.LeftImageItem,
            FFXIClassicStyle.Border.CenterImageItem,
            FFXIClassicStyle.Border.RightImageItem
    ), FFXIClassicStyle)
    return self
end

function FFXIClassicStyle.static()
    local self = setmetatable(CollectionViewStyle.new(
            nil,
            nil,
            FFXIClassicStyle.CenterImageItem,
            FFXIClassicStyle.Border.LeftImageItem,
            FFXIClassicStyle.Border.CenterImageItem,
            FFXIClassicStyle.Border.RightImageItem
    ), FFXIClassicStyle)
    return self
end

function FFXIClassicStyle:getDefaultPickerSize()
    return { width = 180, height = 192 }
end

function FFXIClassicStyle:getDefaultTextInputSize()
    return { width = 250, height = 100 }
end

return FFXIClassicStyle