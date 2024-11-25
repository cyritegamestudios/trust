local Color = require('cylibs/ui/views/color')
local i18n = require('cylibs/i18n/i18n')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local Frame = require('cylibs/ui/views/frame')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local ButtonItem = {}
ButtonItem.__index = ButtonItem
ButtonItem.__type = "ButtonItem"

ButtonItem.DefaultStyle = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        10,
        Color.white,
        Color.new(255, 255, 179, 25),
        0,
        1,
        Color.clear,
        true
)

ButtonItem.State = {}
ButtonItem.State.Default = "Default"
ButtonItem.State.Highlighted = "Highlighted"
ButtonItem.State.Selected = "Selected"

---
-- Creates a new button item with specified text and images.
--
-- @tparam TextItem textItem The text associated with the button.
-- @tparam ImageItem leftImageItem The left image of the button.
-- @tparam ImageItem centerImageItem The center image of the button.
-- @tparam ImageItem rightImageItem The right image of the button.
-- @treturn ButtonItem The newly created button item.
--
function ButtonItem.new(textItem, defaultImageItem, highlightedImageItem, selectedImageItem)
    local self = setmetatable({}, ButtonItem)

    self.textItem = textItem
    self.textItem:setShouldAutoResize(true)

    self.imageItems = {}

    self:setImageItem(defaultImageItem, ButtonItem.State.Default)
    self:setImageItem(highlightedImageItem, ButtonItem.State.Highlighted)
    self:setImageItem(selectedImageItem, ButtonItem.State.Selected)

    local buttonWidth = 0
    local buttonHeight = 0

    local imageItems = defaultImageItem:getAllImageItems(L{ ResizableImageItem.Left, ResizableImageItem.Center, ResizableImageItem.Right })
    for imageItem in imageItems:it() do
        buttonWidth = buttonWidth + imageItem:getSize().width
        buttonHeight = math.max(buttonHeight, imageItem:getSize().height)
    end

    self.size = Frame.new(0, 0, buttonWidth, buttonHeight)
    self.alpha = 255
    self.enabled = true

    return self
end

function ButtonItem.localized(buttonText, localizedText)
    return ButtonItem.default(buttonText, 18, ButtonItem.DefaultStyle, localizedText)
end

---
-- Creates a default ButtonItem with specified text and height.
--
-- @tparam string buttonText The text to display on the button.
-- @tparam number buttonHeight The height of the button.
-- @treturn ButtonItem The created ButtonItem with default properties.
--
function ButtonItem.default(buttonText, buttonHeight, textStyle, localizedText)
    buttonHeight = 16
    textStyle = textStyle or ButtonItem.DefaultStyle

    local centerImageItem = ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_mid.png', 84, buttonHeight)
    centerImageItem:setRepeat(3, 1)

    local centerImageItemHighlighted = ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_mid_selected.png', 84, buttonHeight)
    centerImageItemHighlighted:setRepeat(3, 1)

    local defaultImageItem = ResizableImageItem.new(
            nil,
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_left.png', 8, buttonHeight),
            nil,
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_right.png', 8, buttonHeight),
            centerImageItem
    )
    local highlightedImageItem = ResizableImageItem.new(
            nil,
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_left_selected.png', 8, buttonHeight),
            nil,
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_right_selected.png', 8, buttonHeight),
            centerImageItemHighlighted
    )

    local textItem = TextItem.new(buttonText, textStyle)
    textItem:setLocalizedText(localizedText)

    local buttonItem = ButtonItem.new(
            textItem,
            defaultImageItem,
            highlightedImageItem,
            defaultImageItem
    )
    return buttonItem
end

---
-- Sets the image item associated with the given button state.
-- @tparam ResizableImageItem An image item
--
function ButtonItem:setImageItem(item, buttonState)
    self.imageItems[buttonState] = item
end

---
-- Retrieves the image item associated with the given button state.
-- @tparam ButtonItem.State buttonState Button state
-- @treturn ResizableImageItem An image item
--
function ButtonItem:getImageItem(buttonState)
    return self.imageItems[buttonState]
end

---
-- Gets the button text item.
-- @treturn TextItem The text item.
--
function ButtonItem:getTextItem()
    return self.textItem
end

---
-- Gets the size of the button.
-- @treturn table A table containing the width and height of the button.
--
function ButtonItem:getSize()
    return { width = self.size.width, height = self.size.height }
end

---
-- Sets the alpha (transparency) value of the image item.
--
-- @tparam number alpha The alpha value (0 for fully transparent, 255 for fully opaque).
--
function ButtonItem:setAlpha(alpha)
    self.alpha = alpha
end

---
-- Retrieves the alpha (transparency) value of the image item.
--
-- @treturn number The alpha value (0 for fully transparent, 255 for fully opaque).
--
function ButtonItem:getAlpha()
    return self.alpha
end

---
-- Sets whether the button is enabled.
--
-- @tparam boolean enabled Whether the button is enabled
--
function ButtonItem:setEnabled(enabled)
    self.enabled = enabled
end

---
-- Gets whether the button is enabled.
--
-- @treturn boolean True if the button is enabled
--
function ButtonItem:getEnabled()
    return self.enabled
end

---
-- Checks if this button item is equal to another button item.
--
-- @tparam ButtonItem otherItem The other button item to compare.
-- @treturn boolean True if the button items are equal, false otherwise.
--
function ButtonItem:__eq(otherItem)
    if otherItem.__type ~= ButtonItem.__type then
        return false
    end
    if self:getTextItem():getText() ~= otherItem:getTextItem():getText() then
        return false
    end
    for key, imageItem in pairs(self.imageItems) do
        local otherImageItem = otherItem:getImageItem(key)
        if imageItem ~= otherImageItem then
            return false
        end
    end
    return true
end

return ButtonItem
