local IndexPath = require('cylibs/ui/collection_view/index_path')

local IndexedItem = {}
IndexedItem.__index = IndexedItem
IndexedItem.__type = "IndexedItem"

---
-- Creates a new IndexedItem with the specified item and index path.
--
-- @tparam any item The associated item.
-- @tparam IndexPath indexPath The index path of the item.
-- @treturn IndexedItem The newly created IndexedItem.
--
function IndexedItem.new(item, indexPath)
    local self = setmetatable({}, IndexedItem)
    self.item = item
    self.indexPath = indexPath
    return self
end

---
-- Returns a list of indexed items from the set of items.
--
-- @tparam list items The list of items.
-- @tparam number section The section the items are in.
-- @treturn list List of indexed items
--
function IndexedItem.fromItems(items, section)
    local indexedItems = L{}
    local rowIndex = 1
    for item in items:it() do
        indexedItems:append(IndexedItem.new(item, IndexPath.new(section, rowIndex)))
        rowIndex = rowIndex + 1
    end
    return indexedItems
end

---
-- Returns the associated item of this IndexedItem.
--
-- @treturn any The associated item.
--
function IndexedItem:getItem()
    return self.item
end

---
-- Returns the index path of this IndexedItem.
--
-- @treturn IndexPath The index path of the item.
--
function IndexedItem:getIndexPath()
    return self.indexPath
end

---
-- Checks if this IndexedItem is equal to another.
--
-- @tparam IndexedItem otherItem The other IndexedItem to compare with.
-- @treturn boolean True if the items and index paths are equal, false otherwise.
--
function IndexedItem:__eq(otherItem)
    return otherItem.__type == IndexedItem.__type and self:getIndexPath() == otherItem:getIndexPath()
            and self:getItem() == otherItem:getItem()
end

return IndexedItem
