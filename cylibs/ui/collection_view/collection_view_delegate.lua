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

function CollectionViewDelegate:didMoveCursorToItemAtIndexPath()
    return self.didMoveCursorToItem
end

function CollectionViewDelegate.new(collectionView)
    local self = setmetatable({}, { __index = CollectionViewDelegate })

    self.collectionView = collectionView
    self.id = collectionView.__type or 'unknown'
    self.selectedIndexPaths = S{}
    self.highlightedIndexPaths = S{}

    self.disposeBag = DisposeBag.new()

    self.didSelectItem = Event.newEvent()
    self.didDeselectItem = Event.newEvent()
    self.didHighlightItem = Event.newEvent()
    self.didDehighlightItem = Event.newEvent()
    self.didMoveCursorToItem = Event.newEvent()

    self.events = L{ self.didSelectItem, self.didDeselectItem, self.didHighlightItem, self.didDehighlightItem, self.didMoveCursorToItem }

    return self
end

function CollectionViewDelegate:onMouseEvent(type, x, y, delta)
    local dataSource = self.collectionView:getDataSource()
    for section = 1, dataSource:numberOfSections() do
        local numberOfItems = dataSource:numberOfItemsInSection(section)
        for row = 1, numberOfItems do
            local indexPath = IndexPath.new(section, row)
            local cell = dataSource:cellForItemAtIndexPath(indexPath)
            if cell:isVisible() and cell:isUserInteractionEnabled() then
                if cell:hitTest(x, y) then
                    if type == Mouse.Event.Click then
                        return true
                    elseif type == Mouse.Event.ClickRelease then
                        if not self.collectionView:hasFocus() then
                            -- Consider adding this back to get rid of double cursor issue. I think you need to check
                            -- to see if the focusable is already in the stack. This also causes individual cells to
                            -- be selected though creating a really odd focus stack
                            --self.collectionView:requestFocus()
                        end
                        if not cell:onMouseEvent(type, x, y, delta) then
                            if cell:isSelected() then
                                self:deselectItemAtIndexPath(indexPath)
                            else
                                self:selectItemAtIndexPath(indexPath)
                            end
                        end
                        return true
                    elseif type == Mouse.Event.Move then
                        if not cell:isHighlighted() then
                            self:deHighlightAllItems()
                            self:highlightItemAtIndexPath(indexPath)
                        end
                    elseif type == Mouse.Event.Wheel then
                        return cell:onMouseEvent(type, x, y, delta)
                    end
                    return false
                else
                    if type == Mouse.Event.Move then
                        if cell:isHighlighted() then
                            self:deHighlightItemAtIndexPath(indexPath)
                        end
                    end
                end
            end
        end
    end
    return false
end

function CollectionViewDelegate:shouldClipToBounds(collectionView, view)
    local absolutePosition = collectionView:getAbsolutePosition()
    local viewAbsolutePosition = view:getAbsolutePosition()

    if view:getClipsToBounds() then
        if (viewAbsolutePosition.y < absolutePosition.y or viewAbsolutePosition.y + view.frame.height > absolutePosition.y + collectionView.frame.height)
                or (viewAbsolutePosition.x < absolutePosition.x or viewAbsolutePosition.x + view.frame.width > absolutePosition.x + collectionView.frame.width) then
            return true
        else
            return false
        end
    end
end

---
-- Destroys the CollectionViewDelegate and cleans up any resources.
--
function CollectionViewDelegate:destroy()
    self.isDestroyed = true

    self.disposeBag:destroy()

    self.collectionView = nil

    for event in self.events:it() do
        event:removeAllActions()
    end
end

function CollectionViewDelegate:deleteItemAtIndexPath(indexPath)
    self.highlightedIndexPaths = self.highlightedIndexPaths:filter(function(existingIndexPath) return existingIndexPath ~= indexPath  end)
    --self:didDehighlightItemAtIndexPath():trigger(indexPath)

    self.selectedIndexPaths = self.selectedIndexPaths:filter(function(existingIndexPath) return existingIndexPath ~= indexPath  end)
    --self:didDeselectItemAtIndexPath():trigger(indexPath)
end

---
-- Determines whether the item at the specified index path should be selected.
--
-- @tparam any item The item to check for selection.
-- @tparam IndexPath indexPath The index path of the item.
-- @treturn boolean Returns true if the item should be selected, false otherwise.
--
function CollectionViewDelegate:shouldSelectItemAtIndexPath(indexPath)
    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    return cell:isSelectable() and not cell:isSelected()
end

---
-- Selects the item at the specified index path.
--
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:selectItemAtIndexPath(indexPath)
    if not self:shouldSelectItemAtIndexPath(indexPath) then
        if self.collectionView:getAllowsMultipleSelection() then
            self:deselectItemAtIndexPath(indexPath)
        end
        return
    end
    if not self.collectionView:getAllowsMultipleSelection() then
        self:deHighlightAllItems()
        self:deselectAllItems()
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setSelected(true)

    self.selectedIndexPaths:add(indexPath)

    self:didSelectItemAtIndexPath():trigger(indexPath)
end

function CollectionViewDelegate:selectAllItems()
    if not self.collectionView:getAllowsMultipleSelection() then
        return
    end

    local indexPaths = L{}
    for section = 1, self.collectionView:getDataSource():numberOfSections() do
        for row = 1, self.collectionView:getDataSource():numberOfItemsInSection(section) do
            self:selectItemAtIndexPath(IndexPath.new(section, row))
        end
    end
end

---
-- Selects all items in a section of the collection view.
--
-- @tparam number section Section in the collection view.
--
function CollectionViewDelegate:selectItemsInSection(section)
    for row = 1, self.collectionView:getDataSource():numberOfItemsInSection(section) do
        local indexPath = IndexPath.new(section, row)
        if indexPath.section == section then
            self:selectItemAtIndexPath(indexPath)
        end
    end
end

---
-- Deselects the item at the specified index path.
--
-- @tparam any item The item to deselect.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:deselectItemAtIndexPath(indexPath)
    if self:shouldSelectItemAtIndexPath(indexPath) then
        return
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setSelected(false)

    self.selectedIndexPaths = self.selectedIndexPaths:filter(function(existingIndexPath) return existingIndexPath ~= indexPath  end)

    self:didDeselectItemAtIndexPath():trigger(indexPath)
end

---
-- Deselects all items in the collection view.
--
function CollectionViewDelegate:deselectAllItems()
    for indexPath in self.selectedIndexPaths:it() do
        self:deselectItemAtIndexPath(indexPath)
    end
end

---
-- Deselects all items in given sections.

-- @tparam set sections Sections to deselect
--
function CollectionViewDelegate:deselectItemsInSections(sections)
    for indexPath in self.selectedIndexPaths:it() do
        if sections:contains(indexPath.section) then
            self:deselectItemAtIndexPath(indexPath)
        end
    end
end

---
-- Gets the selected IndexPaths.
--
-- @treturn S Returns the set of selected IndexPaths
--
function CollectionViewDelegate:getSelectedIndexPaths()
    return self.selectedIndexPaths
end

---
-- Determines whether the item at the specified index path should be highlighted.
--
-- @tparam any item The item to check for highlighting.
-- @tparam IndexPath indexPath The index path of the item.
-- @treturn boolean Returns true if the item should be highlighted, false otherwise.
--
function CollectionViewDelegate:shouldHighlightItemAtIndexPath(indexPath)
    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    return not cell:isHighlighted()
end

---
-- Highlights the item at the specified index path.
--
-- @tparam any item The item to highlight.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:highlightItemAtIndexPath(indexPath)
    if not self:shouldHighlightItemAtIndexPath(indexPath) then
        return
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setHighlighted(true)

    self.highlightedIndexPaths:add(indexPath)

    self:didHighlightItemAtIndexPath():trigger(indexPath)
end

---
-- De-highlights the item at the specified index path.
--
-- @tparam any item The item to de-highlight.
-- @tparam IndexPath indexPath The index path of the item.
--
function CollectionViewDelegate:deHighlightItemAtIndexPath(indexPath)
    if self:shouldHighlightItemAtIndexPath(indexPath) then
        return
    end

    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    cell:setHighlighted(false)

    self.highlightedIndexPaths = self.highlightedIndexPaths:filter(function(existingIndexPath) return existingIndexPath ~= indexPath  end)

    self:didDehighlightItemAtIndexPath():trigger(indexPath)
end

---
-- De-highlights all currently highlighted items in the collection view.
--
function CollectionViewDelegate:deHighlightAllItems()
    for indexPath in self.highlightedIndexPaths:it() do
        self:deHighlightItemAtIndexPath(indexPath)
    end
end

---
-- Sets the `indexPath` of the cursor.
--
-- @tparam IndexPath indexPath The new value for `cursorIndexPath`
--
function CollectionViewDelegate:setCursorIndexPath(indexPath)
    if indexPath == nil then
        return
    end
    local cell = self.collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
    if cell then
        self.cursorIndexPath = indexPath

        if not self.collectionView:getAllowsMultipleSelection() and self.collectionView:getAllowsCursorSelection() then
            for selectedIndexPath in self:getSelectedIndexPaths():it() do
                if selectedIndexPath ~= indexPath then
                    self:deselectItemAtIndexPath(selectedIndexPath)
                end
            end
        end

        self:deHighlightAllItems()

        if self.collectionView:hasFocus() then
            if self.collectionView:getAllowsCursorSelection() then
                self:selectItemAtIndexPath(indexPath)
            else
                self:highlightItemAtIndexPath(indexPath)
            end
        end

        self:didMoveCursorToItemAtIndexPath():trigger(self.cursorIndexPath)
    end
end

---
-- Gets the current `indexPath` of the cursor, or nil if there is none.
--
-- @treturn IndexPath The current value of `cursorIndexPath`
--
function CollectionViewDelegate:getCursorIndexPath()
    return self.cursorIndexPath
end

return CollectionViewDelegate
