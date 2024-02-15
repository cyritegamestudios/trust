local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local Frame = require('cylibs/ui/views/frame')
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

---
-- Creates a new button item with specified text and images.
--
-- @tparam TextItem textItem The text associated with the button.
-- @tparam ImageItem leftImageItem The left image of the button.
-- @tparam ImageItem centerImageItem The center image of the button.
-- @tparam ImageItem rightImageItem The right image of the button.
-- @treturn ButtonItem The newly created button item.
--
function ButtonItem.new(
        textItem,
        leftImageItem, centerImageItem, rightImageItem,
        leftImageItemSelected, centerImageItemSelected, rightImageItemSelected
)
    local self = setmetatable({}, ButtonItem)

    self.textItem = textItem
    self.leftImageItem = leftImageItem
    self.centerImageItem = centerImageItem
    self.rightImageItem = rightImageItem
    self.leftImageItemSelected = leftImageItemSelected
    self.centerImageItemSelected = centerImageItemSelected
    self.rightImageItemSelected = rightImageItemSelected

    local width = leftImageItem:getSize().width + centerImageItem:getSize().width + rightImageItem:getSize().width
    local height = math.max(leftImageItem:getSize().height, centerImageItem:getSize().height, rightImageItem:getSize().height)

    self.size = Frame.new(0, 0, width, height)
    self.alpha = 255
    self.enabled = true

    return self
end

---
-- Creates a default ButtonItem with specified text and height.
--
-- @tparam string buttonText The text to display on the button.
-- @tparam number buttonHeight The height of the button.
-- @treturn ButtonItem The created ButtonItem with default properties.
--
function ButtonItem.default(buttonText, buttonHeight)
    buttonHeight = 16
    local centerImageItem = ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_mid.png', 84, buttonHeight)
    centerImageItem:setRepeat(3, 1)

    local centerImageItemSelected = ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_mid_selected.png', 84, buttonHeight)
    centerImageItemSelected:setRepeat(3, 1)

    local buttonItem = ButtonItem.new(
            TextItem.new(buttonText, ButtonItem.DefaultStyle),
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_left.png', 8, buttonHeight),
            centerImageItem,
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_right.png', 8, buttonHeight),
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_left_selected.png', 8, buttonHeight),
            centerImageItemSelected,
            ImageItem.new(windower.addon_path..'assets/buttons/menu_button_bg_right_selected.png', 8, buttonHeight)
    )
    return buttonItem
end

---
-- Retrieves the images associated with this button item.
-- @treturn table A table containing left, center, and right image items.
--
function ButtonItem:getImageItems()
    return { left = self.leftImageItem, center = self.centerImageItem, right = self.rightImageItem }
end

---
-- Retrieves the selected images associated with this button item.
-- @treturn table A table containing left, center, and right image items, or nil if none are specified.
--
function ButtonItem:getSelectedImageItems()
    if self.leftImageItemSelected and self.centerImageItemSelected and self.rightImageItemSelected then
        return { left = self.leftImageItemSelected, center = self.centerImageItemSelected, right = self.rightImageItemSelected }
    end
    return nil
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
    if not otherItem.__type == ButtonItem.__type then
        return false
    end
    return self:getText() == otherItem:getText() and self:getImageItems().left == otherItem:getImageItems().left
            and self:getImageItems().center == otherItem:getImageItems().center and self:getImageItems().right == otherItem:getImageItems().right
end

return ButtonItem
