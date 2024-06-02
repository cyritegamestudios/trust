local ImageTextItem = {}
ImageTextItem.__index = ImageTextItem
ImageTextItem.__type = "ImageTextItem"

---
-- Creates a new ImageTextItem instance.
--
-- @tparam ImageItem imageItem The image item.
-- @tparam TextItem textItem The text item.
-- @treturn ImageTextItem The newly created ImageTextItem instance.
--
function ImageTextItem.new(imageItem, textItem)
    local self = setmetatable({}, ImageTextItem)

    self.imageItem = imageItem
    self.textItem = textItem

    return self
end

---
-- Gets the text item.
--
-- @treturn TextItem The text item.
--
function ImageTextItem:getTextItem()
    return self.textItem
end

---
-- Gets the image item.
--
-- @treturn ImageItem The image item.
--
function ImageTextItem:getImageItem()
    return self.imageItem
end

---
-- Checks if this ImageTextItem is equal to another ImageTextItem.
--
-- @tparam ImageTextItem otherItem The other ImageTextItem to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function ImageTextItem:__eq(otherItem)
    return otherItem.__type == ImageTextItem.__type
            and self:getTextItem() == otherItem:getTextItem()
            and self:getImageItem() == otherItem:getImageItem()
end

return ImageTextItem