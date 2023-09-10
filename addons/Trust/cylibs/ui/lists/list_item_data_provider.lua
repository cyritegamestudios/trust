local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local ListItem = require('cylibs/ui/list_item')

local ListItemDataProvider = {}
ListItemDataProvider.__index = ListItemDataProvider

---
-- Event that triggers when items in the data provider are changed.
--
-- @treturn list ListItems changed.
--
function ListItemDataProvider:onItemsChanged()
    return self.itemsChanged
end

---
-- Event that triggers when items are added to the data provider.
--
-- @treturn list ListItems added.
--
function ListItemDataProvider:onItemsAdded()
    return self.itemsAdded
end

---
-- Event that triggers when items are removed from the data provider.
--
-- @treturn list ListItems removed.
--
function ListItemDataProvider:onItemsRemoved()
    return self.itemsRemoved
end

-- Constructor
function ListItemDataProvider.new()
    local self = setmetatable({}, ListItemDataProvider)

    self.items = L{}
    self.disposeBag = DisposeBag.new()

    -- Events
    self.itemsChanged = Event.newEvent()
    self.itemsAdded = Event.newEvent()
    self.itemsRemoved = Event.newEvent()

    return self
end

function ListItemDataProvider:destroy()
    self:onItemsChanged():removeAllActions()
    self:onItemsAdded():removeAllActions()
    self:onItemsRemoved():removeAllActions()

    for item in self:getItems():it() do
        item:destroy()
    end
    self.items = L{}

    self.disposeBag:destroy()
end

---
-- Check if the data provider contains a specific ListItem.
--
-- @tparam ListItem item The ListItem instance to check for.
-- @treturn bool True if the item is found, false otherwise.
--
function ListItemDataProvider:containsItem(item)
    for existingItem in self.items:it() do
        if item:isEqual(existingItem) then
            return true
        end
    end
    return false
end

---
-- Add a ListItem to the data provider.
--
-- @tparam ListItem item The ListItem instance to add.
--
function ListItemDataProvider:addItem(item)
    self:addItems(L{item})
end

---
-- Add a list of ListItem to the data provider.
--
-- @tparam list items ListItems to add.
--
function ListItemDataProvider:addItems(items)
    local itemsAdded = L{}
    for item in items:it() do
        if not self:containsItem(item) then
            self.items:append(item)
            itemsAdded:append(item)
        end
    end
    if itemsAdded:length() > 0 then
        self:onItemsAdded():trigger(itemsAdded)
    end
end

---
-- Remove a ListItem from the data provider if it exists.
--
-- @tparam ListItem item The ListItem instance to remove.
--
function ListItemDataProvider:removeItem(item)
    local itemIndex = 1
    for existingItem in self.items:it() do
        if item == existingItem then
            local itemRemoved = self.items:remove(itemIndex)
            if itemRemoved:isEqual(item) then
                self:onItemsRemoved():trigger(L{item})

                if self.items:length() >= itemIndex then
                    local itemsAfterRemoved = self.items:slice(itemIndex, self.items:length())
                    self.itemsChanged:trigger(itemsAfterRemoved)
                end
                return
            end
        end
        itemIndex = itemIndex + 1
    end
end

---
-- Update an existing ListItem with a new item having the same identifier.
--
-- @tparam ListItem newItem The new ListItem instance to update with.
--
function ListItemDataProvider:updateItem(newItem)
    local identifier = newItem:getIdentifier()
    local itemIndex = 1

    for existingItem in self.items:it() do
        if existingItem:getIdentifier() == identifier then
            self.items[itemIndex] = newItem

            self:onItemsChanged():trigger(L{newItem})
            return
        end
        itemIndex = itemIndex + 1  -- Increase the index for the next iteration
    end
end

---
-- Get the ListItem at the specified index, if it exists.
--
-- @tparam number itemIndex The index of the item to retrieve.
-- @treturn ListItem|nil The ListItem at the specified index, or nil if it does not exist.
--
function ListItemDataProvider:itemAtIndex(itemIndex)
    return self.items[itemIndex]
end

---
-- Get the list of ListItem instances.
--
-- @treturn L A list containing ListItem instances.
--
function ListItemDataProvider:getItems()
    return self.items
end

---
-- Get the number of items in the data provider.
--
-- @treturn number The number of items.
--
function ListItemDataProvider:numItems()
    return self.items:length()
end

-- Gets the DisposeBag associated with this ListItemDataProvider.
-- @treturn DisposeBag The DisposeBag instance.
function ListItemDataProvider:getDisposeBag()
    return self.disposeBag
end

return ListItemDataProvider
