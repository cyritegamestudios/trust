local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Mouse = require('cylibs/ui/input/mouse')

local CollectionViewDelegate = {}
CollectionViewDelegate.__index = CollectionViewDelegate
CollectionViewDelegate.__type = "CollectionViewDelegate"

function CollectionViewDelegate:didSelectItemAtIndexPath()
    return self.didSelectItem
end

function CollectionViewDelegate:didDeselectItemAtIndexPath()
    return self.didDeselectItem
end

function CollectionViewDelegate:didHighlightItemAtIndexPath()
    return self.didHighlightItem
end

function CollectionViewDelegate:didDehighlightItemAtIndexPath()
    return self.didDehighlightItem
end

function CollectionViewDelegate.new(collectionView)
    local self = setmetatable({}, { __index = CollectionViewDelegate })

    self.collectionView = collectionView
    self.selectedIndexPaths = S{}
    self.highlightedIndexPaths = S{}

    self.disposeBag = DisposeBag.new()

    self.didSelectItem = Event.newEvent()
    self.didDeselectItem = Event.newEvent()
    self.didHighlightItem = Event.newEvent()
    self.didDehighlightItem = Event.newEvent()

    self.events = L{ self.didSelectItem, self.didDeselectItem, self.didHighlightItem, self.didDehighlightItem }

    self.disposeBag:add(Mouse.input():onMouseEvent():addAction(function(type, x, y, delta, blocked)
        local dataSource = collectionView:getDataSource()
        for section = 1, dataSource:numberOfSections() do
            local numberOfItems = dataSource:numberOfItemsInSection(section)
            for row = 1, numberOfItems do
                local indexPath = IndexPath.new(section, row)
                local cell = dataSource:cellForItemAtIndexPath(indexPath)
                if cell:isVisible() and cell:isUserInteractionEnabled() then
                    if cell:hitTest(x, y) then
                        local item = dataSource:itemAtIndexPath(indexPath)
                        if type == Mouse.Event.Click then
                            if cell:isSelected() then
                                self:deselectItemAtIndexPath(item, indexPath)
                            else
                                self:selectItemAtIndexPath(item, indexPath)
                            end
                        elseif type == Mouse.Event.Move then
                            if not cell:isHighlighted() then
                                self:deHighlightAllItems()
                                self:highlightItemAtIndexPath(item, indexPath)
                            end
                        end
                        return true
                    else
                        if type == Mouse.Event.Move then
                            local item = dataSource:itemAtIndexPath(indexPath)
                            if cell:isHighlighted() then
                                self:deHighlightItemAtIndexPath(item, indexPath)
                            end
                        end
                    end
                end
            end
        end
        return false
    end), Mouse.input():onMouseEvent())

    return self
end

---
-- Destroys the CollectionViewDelegate and cleans up any resources.
--
function CollectionViewDelegate:destroy()
    self.disposeBag:destroy()

    self.collectionView = nil

    for event in self.events:it() do
        event:removeAllActions()
    end
end

---
-- Determines whether the item at the specified index path should be selected.
--
-- @tparam any item The item to check for selection.
-- @tparam IndexPath indexPath The index path of the item.
-- @treturn boolean Returns true if the item should be selected, false otherwise.
--
function CollectionViewDelegate:shouldSelectItemAtIndexPath(item, indexPath)
    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    return not cell:isSelected()
end

---
-- Selects the item at the specified index path.
--
-- @tparam any item The item to select.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:selectItemAtIndexPath(item, indexPath)
    if not self:shouldSelectItemAtIndexPath(item, indexPath) then
        return
    end

    if not self.collectionView.allowsMultipleSelection then
        self:deselectAllItems()
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setSelected(true)

    self.selectedIndexPaths:add(indexPath)

    self:didSelectItemAtIndexPath():trigger(item, indexPath)
end

---
-- Deselects the item at the specified index path.
--
-- @tparam any item The item to deselect.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:deselectItemAtIndexPath(item, indexPath)
    if self:shouldSelectItemAtIndexPath(item, indexPath) then
        return
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setSelected(false)

    self.selectedIndexPaths = self.selectedIndexPaths:filter(function(existingIndexPath) return existingIndexPath ~= indexPath  end)

    self:didDeselectItemAtIndexPath():trigger(item, indexPath)
end

---
-- Deselects all items in the collection view.
--
function CollectionViewDelegate:deselectAllItems()
    for indexPath in self.selectedIndexPaths:it() do
        local item = self.collectionView:getDataSource():itemAtIndexPath(indexPath)
        self:deselectItemAtIndexPath(item, indexPath)
    end
end

---
-- Determines whether the item at the specified index path should be highlighted.
--
-- @tparam any item The item to check for highlighting.
-- @tparam IndexPath indexPath The index path of the item.
-- @treturn boolean Returns true if the item should be highlighted, false otherwise.
--
function CollectionViewDelegate:shouldHighlightItemAtIndexPath(item, indexPath)
    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    return not cell:isHighlighted()
end

---
-- Highlights the item at the specified index path.
--
-- @tparam any item The item to highlight.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:highlightItemAtIndexPath(item, indexPath)
    if not self:shouldHighlightItemAtIndexPath(item, indexPath) then
        return
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setHighlighted(true)

    self.highlightedIndexPaths:add(indexPath)

    self:didHighlightItemAtIndexPath():trigger(item, indexPath)
end

---

-- De-highlights the item at the specified index path.
--
-- @tparam any item The item to de-highlight.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:deHighlightItemAtIndexPath(item, indexPath)
    if self:shouldHighlightItemAtIndexPath(item, indexPath) then
        return
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setHighlighted(false)

    self.highlightedIndexPaths = self.highlightedIndexPaths:filter(function(existingIndexPath) return existingIndexPath ~= indexPath  end)

    self:didDehighlightItemAtIndexPath():trigger(item, indexPath)
end

---
-- De-highlights all currently highlighted items in the collection view.
--
function CollectionViewDelegate:deHighlightAllItems()
    for indexPath in self.highlightedIndexPaths:it() do
        local item = self.collectionView:getDataSource():itemAtIndexPath(indexPath)
        self:deHighlightItemAtIndexPath(item, indexPath)
    end
end


return CollectionViewDelegate
