local CollectionViewCellCache = {}
CollectionViewCellCache.__index = CollectionViewCellCache
CollectionViewCellCache.__class = "CollectionViewCellCache"
CollectionViewCellCache.__type = "CollectionViewCellCache"

---
-- Creates a new CollectionViewCellCache that caches cells.
--
-- @tparam function cellForItem Function that creates a cell from an item and index path.
-- @treturn CollectionViewCellCache The newly created collection view cell cache instance.
--
function CollectionViewCellCache.new(cellForItem)
    local self = setmetatable({}, CollectionViewCellCache)
    self.cellForItem = cellForItem
    self.reusableCellsForType = {}
    return self
end

function CollectionViewCellCache:destroy()
    self:clear()
end

---
-- Returns a cell for an item from the reuse pool if possible. If no cell exists, a new
-- cell is created.
-- @tparam any item The item.
-- @tparam IndexPath indexPath The index path.
-- @treturn CollectionViewCell Collection view cell.
--
function CollectionViewCellCache:dequeueReusableCellForItem(item, indexPath)
    local reuseIdentifier = item.__type
    local cachedCell = (self.reusableCellsForType[reuseIdentifier] or L{}):firstWhere(function(cell)
        return not cell:isVisible()
    end)
    if cachedCell == nil then
        cachedCell = self.cellForItem(item, indexPath)
        self.reusableCellsForType[reuseIdentifier] = L{ cachedCell }
    end
    return cachedCell
end

function CollectionViewCellCache:recycleCell(cell)
    for _, cells in pairs(self.reusableCellsForType) do
        for cell in cells:it() do

        end
    end
end

---
-- Clears the cache, destroying all the cached cells.
--
function CollectionViewCellCache:clear()
    for _, cells in pairs(self.reusableCellsForType) do
        for cell in cells:it() do
            cell:setVisible(false)
            cell:destroy()
        end
    end
    self.reusableCellsForType = {}
end

return CollectionViewCellCache
