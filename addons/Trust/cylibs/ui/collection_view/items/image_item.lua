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
-- Checks if this ImageItem is equal to another.
-- @tparam ImageItem otherItem The other ImageItem to compare with.
-- @treturn boolean True if the ImageItems are equal, false otherwise.
--
function ImageItem:__eq(otherItem)
    return self.imagePath == otherItem:getImagePath() and self.frame == otherItem.frame
end

return ImageItem
