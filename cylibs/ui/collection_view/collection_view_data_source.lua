local CollectionViewCellCache = require('cylibs/ui/collection_view/collection_view_cell_cache')
local ContainerCollectionViewCell = require('cylibs/ui/collection_view/cells/container_collection_view_cell')
local Event = require('cylibs/events/Luvent')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local SectionHeaderCollectionViewCell = require('cylibs/ui/collection_view/cells/section_header_collection_view_cell')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local ViewItem = require('cylibs/ui/collection_view/items/view_item')


-- Define a simple collection data source table
local CollectionViewDataSource = {}
CollectionViewDataSource.__index = CollectionViewDataSource

function CollectionViewDataSource:onItemsWillChange()
    return self.itemsWillChange
end

function CollectionViewDataSource:onItemsChanged()
    return self.itemsChanged
end

-- Maps item types to cell initializers
local typeMap = {
    [ImageItem.__type] = ImageCollectionViewCell.new,
    [TextItem.__type] = TextCollectionViewCell.new,
    [ViewItem.__type] = ContainerCollectionViewCell.new,
}

-- Initialize a new collection
function CollectionViewDataSource.new(cellForItem)
    local self = setmetatable({}, CollectionViewDataSource)

    self.cellForItem = cellForItem or function(item, _)
        local cellConstructor = typeMap[item.__type]
        if cellConstructor then
            return cellConstructor(item)
        end
        return nil
    end
    self.sections = {}
    self.sectionHeaderItems = {}
    self.cellCache = {}
    self.sectionCellCache = {}
    self.itemsWillChange = Event.newEvent()
    self.itemsChanged = Event.newEvent()

    return self
end

function CollectionViewDataSource:destroy()
    self.itemsWillChange:removeAllActions()
    self.itemsChanged:removeAllActions()

    for _, section in ipairs(self.cellCache) do
        for _, cachedCell in ipairs(section) do
            cachedCell:destroy()
        end
    end

    for _, cachedCell in ipairs(self.sectionCellCache) do
        cachedCell:destroy()
    end
end

-- Add an item to a specific section, creating the section if it doesn't exist
function CollectionViewDataSource:addItem(item, indexPath)
    self:addItems(L{ IndexedItem.new(item, indexPath) })
end

---
-- Adds a list of IndexedItems to the collection view.
--
-- @tparam list indexedItems A list of IndexedItems containing both items and their corresponding index paths.
--
function CollectionViewDataSource:addItems(indexedItems)
    local snapshot = self:createSnapshot()  -- Create a snapshot before making changes

    for indexedItem in indexedItems:it() do
        local section = indexedItem:getIndexPath().section
        local row = indexedItem:getIndexPath().row

        if not self.sections[section] then
            table.insert(self.sections, section, {items = {}})
        end
        table.insert(self.sections[section].items, row, indexedItem:getItem())
    end

    -- Generate a diff
    local diff = self:generateDiff(snapshot)

    -- Trigger the itemsChanged event
    self.itemsChanged:trigger(diff.added, diff.removed, diff.updated)
end

function CollectionViewDataSource:setItemForSectionHeader(section, sectionHeaderItem)
    self.sectionHeaderItems[section] = sectionHeaderItem

    -- TODO: reload all
end

function CollectionViewDataSource:headerItemForSection(section)
    return self.sectionHeaderItems[section]
end

-- Remove an item at a specific IndexPath
function CollectionViewDataSource:removeItem(indexPath)
    if not self:itemAtIndexPath(indexPath) then
        return
    end
    local snapshot = self:createSnapshot()  -- Create a snapshot before making changes

    table.remove(self.sections[indexPath.section].items, indexPath.row)

    -- Generate a diff
    local diff = self:generateDiff(snapshot)

    self.itemsWillChange:trigger(diff.added, diff.removed, diff.updated)

    for _, indexPath in pairs(diff.removed) do
        local cachedCell = self.cellCache[indexPath.section][indexPath.row]
        if cachedCell then
            cachedCell:destroy()
            self.cellCache[indexPath.section][indexPath.row] = nil
        end
    end

    -- Trigger the itemsChanged event
    self.itemsChanged:trigger(diff.added, diff.removed, diff.updated)
end

function CollectionViewDataSource:removeItems(indexPaths)
    local snapshot = self:createSnapshot()  -- Create a snapshot before making changes

    for indexPath in indexPaths:it() do
        table.remove(self.sections[indexPath.section].items, indexPath.row)
    end

    -- Generate a diff
    local diff = self:generateDiff(snapshot)

    self.itemsWillChange:trigger(diff.added, diff.removed, diff.updated)

    for _, indexPath in pairs(diff.removed) do
        local cachedCell = self.cellCache[indexPath.section][indexPath.row]
        if cachedCell then
            cachedCell:destroy()
            self.cellCache[indexPath.section][indexPath.row] = nil
        end
    end

    -- Trigger the itemsChanged event
    self.itemsChanged:trigger(diff.added, diff.removed, diff.updated)
end

function CollectionViewDataSource:removeItemsInSection(section)
    if not self.sections[section] then
        return
    end

    local indexPathsToRemove = L{}
    for rowIndex = 1, self:numberOfItemsInSection(section) do
        indexPathsToRemove:append(IndexPath.new(section, rowIndex))
    end

    self:removeItems(indexPathsToRemove)
end

function CollectionViewDataSource:removeAllItems()
    local snapshot = self:createSnapshot()  -- Create a snapshot before making changes

    -- Iterate through all sections and remove their items
    for _, section in ipairs(self.sections) do
        section.items = {}
    end

    -- Generate a diff
    local diff = self:generateDiff(snapshot)

    self.itemsWillChange:trigger(diff.added, diff.removed, diff.updated)

    for _, indexPath in pairs(diff.removed) do
        local cachedCell = self.cellCache[indexPath.section][indexPath.row]
        if cachedCell then
            cachedCell:destroy()
            self.cellCache[indexPath.section][indexPath.row] = nil
        end
    end
    self.cellCache = {}

    -- Trigger the itemsChanged event
    self.itemsChanged:trigger(diff.added, diff.removed, diff.updated)
end

function CollectionViewDataSource:swapItems(indexedItem1, indexedItem2)
    self:updateItems(L{ IndexedItem.new(indexedItem1:getItem(), indexedItem2:getIndexPath()), IndexedItem.new(indexedItem2:getItem(), indexedItem1:getIndexPath()) })
end

-- Update an item at a specific IndexPath
function CollectionViewDataSource:updateItem(item, indexPath)
    self:updateItems(L{ IndexedItem.new(item, indexPath) })
end

function CollectionViewDataSource:updateItems(indexedItems)
    local snapshot = self:createSnapshot()  -- Create a snapshot before making changes

    local itemsToAdd = L{}
    for indexedItem in indexedItems:it() do
        local currentSection = self.sections[indexedItem:getIndexPath().section]
        if currentSection then
            local currentItem = self.sections[indexedItem:getIndexPath().section].items[indexedItem:getIndexPath().row]
            if not (currentItem and currentItem == indexedItem:getItem()) then
                self.sections[indexedItem:getIndexPath().section].items[indexedItem:getIndexPath().row] = indexedItem:getItem()
            end
        else
            itemsToAdd:append(indexedItem)
        end
        local cachedCell = self.cellCache[indexedItem:getIndexPath().section] and self.cellCache[indexedItem:getIndexPath().section][indexedItem:getIndexPath().row]
        if cachedCell then
            if self.sizeForItem ~= nil then
                cachedCell:setItemSize(self.sizeForItem(indexedItem:getItem(), indexedItem:getIndexPath()))
            end
            -- FIXME: revert this if it causes errors
            cachedCell:setNeedsLayout()
            cachedCell:layoutIfNeeded()
        end
    end

    -- Generate a diff
    local diff = self:generateDiff(snapshot)

    -- Trigger the itemsChanged event
    self.itemsChanged:trigger(diff.added, diff.removed, diff.updated)

    if itemsToAdd:length() > 0 then
        self:addItems(itemsToAdd)
    end
end

-- Get the number of sections in the collection
function CollectionViewDataSource:numberOfSections()
    return #self.sections
end

-- Get the number of items in a specific section
function CollectionViewDataSource:numberOfItemsInSection(section)
    if not self.sections[section] then
        return 0
    end
    return #self.sections[section].items
end

-- Get an item at a specific IndexPath
function CollectionViewDataSource:itemAtIndexPath(indexPath)
    return self.sections[indexPath.section].items[indexPath.row]
end

function CollectionViewDataSource:getNextIndexPath(indexPath, wrap)
    if self:numberOfItemsInSection(indexPath.section) >= indexPath.row + 1 then
        return IndexPath.new(indexPath.section, indexPath.row + 1)
    elseif self:numberOfSections() >= indexPath.section + 1 and self:numberOfItemsInSection(indexPath.section) >= 1 then
        return IndexPath.new(indexPath.section + 1, 1)
    else
        if wrap then
            return IndexPath.new(1, 1)
        else
            return indexPath
        end
    end
end

function CollectionViewDataSource:getPreviousIndexPath(indexPath, wrap)
    if indexPath.row > 1 then
        return IndexPath.new(indexPath.section, indexPath.row - 1)
    elseif indexPath.section > 1 then
        return IndexPath.new(indexPath.section - 1, self:numberOfItemsInSection(indexPath.section - 1))
    else
        if wrap then
            return IndexPath.new(self:numberOfSections(), self:numberOfItemsInSection(self:numberOfSections()))
        else
            return indexPath
        end
    end
end

-- Get the cell for a specific IndexPath
function CollectionViewDataSource:cellForItemAtIndexPath(indexPath)
    local item = self:itemAtIndexPath(indexPath)

    -- Check if a cell for this index path already exists in the cache
    local cachedCell = self.cellCache[indexPath.section] and self.cellCache[indexPath.section][indexPath.row]

    if cachedCell then
        return cachedCell
    else
        local newCell = self.cellForItem(item, indexPath)
        newCell:setClipsToBounds(true)

        -- Create a cache for the section if it doesn't exist
        self.cellCache[indexPath.section] = self.cellCache[indexPath.section] or {}
        self.cellCache[indexPath.section][indexPath.row] = newCell

        return newCell
    end
end

-- Get the header view cell for a specific section, if it exists
function CollectionViewDataSource:headerViewForSection(section)
    local sectionHeaderItem = self:headerItemForSection(section)
    if sectionHeaderItem then
        local cachedCell = self.sectionCellCache[section]
        if cachedCell then
            return cachedCell
        else
            local newCell = SectionHeaderCollectionViewCell.new(sectionHeaderItem)
            newCell:setClipsToBounds(true)

            self.sectionCellCache[section] = newCell

            return newCell
        end
    end
    return nil
end

-- Helper function to create a snapshot of the dataSource
function CollectionViewDataSource:createSnapshot()
    local snapshot = {}
    for sectionIndex, section in ipairs(self.sections) do
        snapshot[sectionIndex] = { items = {} }
        for rowIndex, item in ipairs(section.items) do
            snapshot[sectionIndex].items[rowIndex] = item
        end
    end
    return snapshot
end

-- Generate a diff based on changes to the dataSource
--[[function CollectionViewDataSource:generateDiff(snapshot)
    local addedIndexPaths = T{}
    local removedIndexPaths = T{}
    local updatedIndexPaths = T{}

    -- Compare sections and items
    for sectionIndex, section in ipairs(self.sections) do
        local snapshotSection = snapshot[sectionIndex]
        if not snapshotSection then
            -- Entire section is added
            for rowIndex, _ in ipairs(section.items) do
                table.insert(addedIndexPaths, IndexPath.new(sectionIndex, rowIndex))
            end
        else
            -- Compare items within section
            for rowIndex, _ in ipairs(section.items) do
                local indexPath = IndexPath.new(sectionIndex, rowIndex)
                local snapshotItem = snapshotSection.items[rowIndex]
                local newItem = section.items[rowIndex]
                if snapshotItem ~= newItem then
                    table.insert(updatedIndexPaths, indexPath)
                end
            end
        end
    end

    -- Check for removed sections or items
    for sectionIndex, section in ipairs(snapshot) do
        local selfSection = self.sections[sectionIndex]
        if not selfSection then
            -- Entire section is removed
            for rowIndex, _ in ipairs(section.items) do
                table.insert(removedIndexPaths, IndexPath.new(sectionIndex, rowIndex))
            end
        else
            -- Compare items within section
            for rowIndex, _ in ipairs(section.items) do
                local indexPath = IndexPath.new(sectionIndex, rowIndex)
                local snapshotItem = section.items[rowIndex]
                local newItem = selfSection.items[rowIndex]
                if snapshotItem ~= newItem then
                    table.insert(updatedIndexPaths, indexPath)
                end
            end
        end
    end

    return {
        added = addedIndexPaths,
        removed = removedIndexPaths,
        updated = updatedIndexPaths
    }
end]]

function CollectionViewDataSource:generateDiff(snapshot)
    local addedIndexPaths = T{}
    local removedIndexPaths = T{}
    local updatedIndexPaths = T{}

    -- Compare sections and items
    for sectionIndex, section in ipairs(self.sections) do
        local snapshotSection = snapshot[sectionIndex]
        if not snapshotSection then
            -- Entire section is added
            for rowIndex, _ in ipairs(section.items) do
                table.insert(addedIndexPaths, IndexPath.new(sectionIndex, rowIndex))
            end
        else
            -- Compare items within section
            for rowIndex, _ in ipairs(section.items) do
                local indexPath = IndexPath.new(sectionIndex, rowIndex)
                local snapshotItem = snapshotSection.items[rowIndex]
                local newItem = section.items[rowIndex]
                if snapshotItem ~= newItem then
                    table.insert(updatedIndexPaths, indexPath)
                end
            end

            -- Check for removed or shifted items
            for rowIndex, _ in ipairs(snapshotSection.items) do
                local indexPath = IndexPath.new(sectionIndex, rowIndex)
                if not section.items[rowIndex] then
                    table.insert(removedIndexPaths, indexPath)
                end
            end
        end
    end

    -- Check for removed sections or items
    for sectionIndex, section in ipairs(snapshot) do
        local selfSection = self.sections[sectionIndex]
        if not selfSection then
            -- Entire section is removed
            for rowIndex, _ in ipairs(section.items) do
                table.insert(removedIndexPaths, IndexPath.new(sectionIndex, rowIndex))
            end
        else
            -- Compare items within section
            for rowIndex, _ in ipairs(section.items) do
                local indexPath = IndexPath.new(sectionIndex, rowIndex)
                local snapshotItem = section.items[rowIndex]
                local newItem = selfSection.items[rowIndex]
                if snapshotItem ~= newItem then
                    table.insert(updatedIndexPaths, indexPath)
                end
            end
            -- Check for added items
            local snapshotSection = snapshot[sectionIndex]
            for rowIndex, _ in ipairs(selfSection.items) do
                local indexPath = IndexPath.new(sectionIndex, rowIndex)
                if not snapshotSection.items[rowIndex] then
                    local newItem = selfSection.items[rowIndex]
                    table.insert(addedIndexPaths, indexPath)
                end
            end
        end
    end

    return {
        added = addedIndexPaths,
        removed = removedIndexPaths,
        updated = updatedIndexPaths
    }
end


return CollectionViewDataSource

