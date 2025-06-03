local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TextFieldItem = require('cylibs/ui/collection_view/items/text_field_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')

local FFXITextFieldItem = setmetatable({}, {__index = TextFieldItem })
FFXITextFieldItem.__index = FFXITextFieldItem

function FFXITextFieldItem.new(placeholderText, validator, width, height)
    width = width or 175
    height = height or 32

    local buttonHeight = height
    local textHeight = 16

    local centerImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/text_field_background_middle.png', width, buttonHeight)
    centerImageItem:setRepeat(150 / 10, 1)

    local defaultImageItem = ResizableImageItem.new(
            nil,
            ImageItem.new(windower.addon_path..'assets/backgrounds/text_field_background_left.png', 8, buttonHeight),
            nil,
            ImageItem.new(windower.addon_path..'assets/backgrounds/text_field_background_right.png', 8, buttonHeight),
            centerImageItem
    )

    local textItem = TextItem.new(placeholderText, ButtonItem.DefaultStyle)
    textItem:setOffset(0, (buttonHeight - textHeight) / 2)

    local textFieldItem = TextFieldItem.new(
            textItem,
            defaultImageItem,
            defaultImageItem,
            defaultImageItem,
            validator or function(text)
                return text:length() >= 0 and text:length() < 20
            end
    )

    local self = setmetatable(textFieldItem, FFXITextFieldItem)
    self.size = { width = width, height = height }
    return self
end

---
-- Gets the width.
--
-- @treturn number The width.
--
function FFXITextFieldItem:getSize()
    return self.size
end

return FFXITextFieldItem