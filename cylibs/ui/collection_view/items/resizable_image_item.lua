local ResizableImageItem = {}
ResizableImageItem.__index = ResizableImageItem
ResizableImageItem.__type = "ResizableImageItem"

ResizableImageItem.Top = "Top"
ResizableImageItem.Left = "Left"
ResizableImageItem.Bottom = "Bottom"
ResizableImageItem.Right = "Right"
ResizableImageItem.Center = "Center"

---
-- Creates a new ResizableImageItem for an image that can be resized using slicing.
-- @tparam ImageItem topImageItem The image item for the top slice
-- @tparam ImageItem leftImageItem The image item for the left slice
-- @tparam ImageItem bottomImageItem The image item for the bottom slice
-- @tparam ImageItem rightImageItem The image item for the right slice
-- @tparam ImageItem centerImageItem The image item for the center slice
-- @treturn ResizableImageItem The newly created resizable ImageItem.
--
function ResizableImageItem.new(topImageItem, leftImageItem, bottomImageItem, rightImageItem, centerImageItem)
    local self = setmetatable({}, ResizableImageItem)

    self.imageItems = {}

    self:setImageItem(topImageItem, ResizableImageItem.Top)
    self:setImageItem(leftImageItem, ResizableImageItem.Left)
    self:setImageItem(bottomImageItem, ResizableImageItem.Bottom)
    self:setImageItem(centerImageItem, ResizableImageItem.Center)
    self:setImageItem(rightImageItem, ResizableImageItem.Right)

    return self
end

---
-- Gets the path of the image associated with this item.
-- @tparam ImageItem imageItem The image item for the given key.
-- @tparam string key The image item key
--
function ResizableImageItem:setImageItem(imageItem, key)
    self.imageItems[key] = imageItem
end

---
-- Returns the ImageItem with the given key, if it exists.
-- @tparam string key Image item key.
-- @tparam ImageItem ImageItem with the given key, or nil if it does not exist
--
function ResizableImageItem:getImageItem(key)
    return self.imageItems[key]
end

---
-- Returns all non-nil ImageItems.
-- @tparam list List of non-nil image items
--
function ResizableImageItem:getAllImageItems(keys)
    local imageItems = L{}

    keys = keys or T(self.imageItems):keyset()
    for key in keys:it() do
        local imageItem = self.imageItems[key]
        if imageItem then
            imageItems:append(imageItem)
        end
    end
    return imageItems
end

---
-- Checks if this ResizableImageItem is equal to another.
-- @tparam ResizableImageItem otherItem The other ResizableImageItem to compare with.
-- @treturn boolean True if the ResizableImageItems are equal, false otherwise.
--
function ResizableImageItem:__eq(otherItem)
    for key, imageItem in pairs(self.imageItems) do
        local otherImageItem = otherItem:getImageItem(key)
        if imageItem ~= otherImageItem then
            return false
        end
    end
    return true
end

return ResizableImageItem
