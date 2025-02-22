local Frame = require('cylibs/ui/views/frame')

local ToggleButtonItem = {}
ToggleButtonItem.__index = ToggleButtonItem
ToggleButtonItem.__type = "ToggleButtonItem"

ToggleButtonItem.State = {}
ToggleButtonItem.State.Enabled = "Enabled"
ToggleButtonItem.State.Disabled = "Disabled"

---
-- Creates a new button item with specified text and images.
--
-- @tparam ImageItem enabledImageItem The enabled image of the button.
-- @tparam ImageItem disabledImageItem The disabled image of the button.
-- @treturn ButtonItem The newly created toggle button item.
--
function ToggleButtonItem.new(enabledImageItem, disabledImageItem)
    local self = setmetatable({}, ToggleButtonItem)

    self.imageItems = {}

    self:setImageItem(enabledImageItem, ToggleButtonItem.State.Enabled)
    self:setImageItem(disabledImageItem, ToggleButtonItem.State.Disabled)

    local buttonWidth = 0
    local buttonHeight = 0

    for imageItem in L{ enabledImageItem, disabledImageItem }:it() do
        buttonWidth = math.max(buttonWidth, imageItem:getSize().width)
        buttonHeight = math.max(buttonHeight, imageItem:getSize().height)
    end

    self.size = Frame.new(0, 0, buttonWidth, buttonHeight)
    self.alpha = 255
    self.enabled = true

    return self
end

---
-- Sets the image item associated with the given button state.
-- @tparam ImageItem An image item
--
function ToggleButtonItem:setImageItem(item, buttonState)
    self.imageItems[buttonState] = item
end

---
-- Retrieves the image item associated with the given button state.
-- @tparam ButtonItem.State buttonState Button state
-- @treturn ImageItem An image item
--
function ToggleButtonItem:getImageItem(buttonState)
    return self.imageItems[buttonState]
end

---
-- Gets the size of the button.
-- @treturn table A table containing the width and height of the button.
--
function ToggleButtonItem:getSize()
    return { width = self.size.width, height = self.size.height }
end

---
-- Sets the alpha (transparency) value of the image item.
--
-- @tparam number alpha The alpha value (0 for fully transparent, 255 for fully opaque).
--
function ToggleButtonItem:setAlpha(alpha)
    self.alpha = alpha
end

---
-- Retrieves the alpha (transparency) value of the image item.
--
-- @treturn number The alpha value (0 for fully transparent, 255 for fully opaque).
--
function ToggleButtonItem:getAlpha()
    return self.alpha
end

---
-- Sets whether the button is enabled.
--
-- @tparam boolean enabled Whether the button is enabled
--
function ToggleButtonItem:setEnabled(enabled)
    self.enabled = enabled
end

---
-- Gets whether the button is enabled.
--
-- @treturn boolean True if the button is enabled
--
function ToggleButtonItem:getEnabled()
    return self.enabled and self.enabled ~= 0
end

---
-- Checks if this toggle button item is equal to another button item.
--
-- @tparam ToggleButtonItem otherItem The other button item to compare.
-- @treturn boolean True if the button items are equal, false otherwise.
--
function ToggleButtonItem:__eq(otherItem)
    if not otherItem.__type == ToggleButtonItem.__type then
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

return ToggleButtonItem
