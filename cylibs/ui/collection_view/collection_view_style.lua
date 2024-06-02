local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')

local CollectionViewStyle = {}
CollectionViewStyle.__index = CollectionViewStyle
CollectionViewStyle.__type = "CollectionViewStyle"

function CollectionViewStyle.empty()
    return CollectionViewStyle.new()
end

---
-- Creates a new CollectionViewStyle that determines the appearance of a CollectionView.
--
-- @tparam ImageItem cursorItem Cursor image item
-- @tparam ResizableImageItem scrollItem Scroll track and scroll button image items
-- @tparam ImageItem backgroundItem Background image item
--
-- @treturn CollectionViewStyle The newly created CollectionViewStyle instance.
--
function CollectionViewStyle.new(cursorItem, scrollItem, backgroundItem, borderLeftItem, borderCenterItem, borderRightItem)
    local self = setmetatable({}, CollectionViewStyle)

    self.cursorItem = cursorItem
    self.scrollItem = scrollItem
    self.backgroundItem = backgroundItem
    self.borderLeftItem = borderLeftItem
    self.borderCenterItem = borderCenterItem
    self.borderRightItem = borderRightItem

    return self
end

---
-- Gets the ImageItem for the background.
--
-- @treturn ImageItem ImageItem for the background.
--
function CollectionViewStyle:getBackgroundItem()
    return self.backgroundItem
end

---
-- Gets the ImageItem for the background.
--
-- @treturn ImageItem ImageItem for the background.
--
function CollectionViewStyle:getBorderLeftItem()
    return self.borderLeftItem
end

---
-- Gets the ImageItem for the background.
--
-- @treturn ImageItem ImageItem for the background.
--
function CollectionViewStyle:getBorderCenterItem()
    return self.borderCenterItem
end

---
-- Gets the ImageItem for the background.
--
-- @treturn ImageItem ImageItem for the background.
--
function CollectionViewStyle:getBorderRightItem()
    return self.borderRightItem
end

---
-- Gets the ImageItem for the cursor.
--
-- @treturn ImageItem ImageItem for the cursor.
--
function CollectionViewStyle:getCursorItem()
    return self.cursorItem
end

---
-- Gets the ImageItem for the scroll track.
--
-- @treturn ImageItem Image item for the scroll track.
--
function CollectionViewStyle:getScrollTrackItem()
    return self.scrollItem:getImageItem(ResizableImageItem.Center)
end

---
-- Gets the ImageItem for the scroll forward button.
--
-- @treturn ImageItem Image item for the scroll forward button.
--
function CollectionViewStyle:getScrollForwardItem()
    return self.scrollItem:getImageItem(ResizableImageItem.Top)
end

---
-- Gets the ImageItem for the scroll back button.
--
-- @treturn ImageItem Image item for the scroll back button.
--
function CollectionViewStyle:getScrollBackItem()
    return self.scrollItem:getImageItem(ResizableImageItem.Bottom)
end

function CollectionViewStyle:getDefaultSize()
    return { width = 500, height = 500}
end

function CollectionViewStyle:getDefaultPickerSize()
    return { width = 500, height = 500 }
end

return CollectionViewStyle