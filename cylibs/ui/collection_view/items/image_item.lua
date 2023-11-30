local Frame = require('cylibs/ui/views/frame')

local ImageItem = {}
ImageItem.__index = ImageItem
ImageItem.__type = "ImageItem"

---
-- Creates a new ImageItem.
-- @tparam string imagePath The path to the image file.
-- @tparam number width The width of the image.
-- @tparam number height The height of the image.
-- @treturn ImageItem The newly created ImageItem.
--
function ImageItem.new(imagePath, width, height)
    local self = setmetatable({}, ImageItem)
    self.imagePath = imagePath
    self.size = Frame.new(0, 0, width, height)
    self.alpha = 255
    self.repeatX = 1
    self.repeatY = 1
    return self
end

---
-- Gets the path of the image associated with this item.
-- @treturn string The image path.
--
function ImageItem:getImagePath()
    return self.imagePath
end

---
-- Gets the size of the image.
-- @treturn table A table containing the width and height of the image.
--
function ImageItem:getSize()
    return { width = self.size.width, height = self.size.height }
end

---
-- Sets the pattern repeat of the image.
-- @tparam number x Repeat X
-- @tparam number y Repeat Y
--
function ImageItem:setRepeat(x, y)
    self.repeatX = x
    self.repeatY = y
end

---
-- Get the pattern repeat of the image.
-- @treturn Frame A frame containing the repeatX and repeatY
--
function ImageItem:getRepeat()
    return Frame.new(self.repeatX, self.repeatY)
end

---
-- Sets the alpha (transparency) value of the image item.
--
-- @tparam number alpha The alpha value (0 for fully transparent, 255 for fully opaque).
--
function ImageItem:setAlpha(alpha)
    self.alpha = alpha
end

---
-- Retrieves the alpha (transparency) value of the image item.
--
-- @treturn number The alpha value (0 for fully transparent, 255 for fully opaque).
--
function ImageItem:getAlpha()
    return self.alpha
end


---
-- Checks if this ImageItem is equal to another.
-- @tparam ImageItem otherItem The other ImageItem to compare with.
-- @treturn boolean True if the ImageItems are equal, false otherwise.
--
function ImageItem:__eq(otherItem)
    return self.imagePath == otherItem:getImagePath() and self.frame == otherItem.frame
end

return ImageItem
