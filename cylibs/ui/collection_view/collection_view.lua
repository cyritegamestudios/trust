local CollectionViewDelegate = require('cylibs/ui/collection_view/collection_view_delegate')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Frame = require('cylibs/ui/views/frame')
local ScrollView = require('cylibs/ui/scroll_view/scroll_view')

local CollectionView = setmetatable({}, {__index = ScrollView })
CollectionView.__index = CollectionView
CollectionView.__class = "CollectionView"

---
-- Creates a new CollectionView instance with the specified data source and layout.
--
-- @tparam CollectionViewDataSource dataSource The data source providing content for the collection view.
-- @tparam CollectionViewLayout layout The layout strategy for arranging items in the collection view.
-- @tparam CollectionViewDelegate delegate (optional) The delegate for interacting with items in the collection view.
-- @treturn CollectionView The newly created CollectionView instance.
--
function CollectionView.new(dataSource, layout, delegate, cursorImageItem)
    local self = setmetatable(ScrollView.new(Frame.zero()), CollectionView)

    self.layout = layout
    self.dataSource = dataSource
    self.delegate = delegate or CollectionViewDelegate.new(self)
    self.allowsMultipleSelection = false
    self.allowsCursorSelection = false
    self.cursorImageItem = cursorImageItem

    if cursorImageItem then
        self.selectionBackground = ImageCollectionViewCell.new(cursorImageItem)

        self:getContentView():addSubview(self.selectionBackground)

        self:getDisposeBag():addAny(L{ self.selectionBackground })

        self.selectionBackground:setVisible(self:hasFocus())
        self.selectionBackground:setNeedsLayout()
        self.selectionBackground:layoutIfNeeded()

        self.delegate:didSelectItemAtIndexPath():addAction(function(indexPath)
            self:getDelegate():setCursorIndexPath(indexPath)
        end)
    end

    self:getDisposeBag():addAny(L{ self.delegate, self.dataSource, self.layout, self.contentView })

    self.dataSource:onItemsWillChange():addAction(function(addedIndexPaths, removedIndexPaths, updatedIndexPaths)
        for _, indexPath in pairs(removedIndexPaths) do
            self:getDelegate():deleteItemAtIndexPath(indexPath)
        end
    end)
    self.dataSource:onItemsChanged():addAction(function(addedIndexPaths, removedIndexPaths, updatedIndexPaths)
        self.layout:setNeedsLayout(self, addedIndexPaths, removedIndexPaths, updatedIndexPaths)

        if removedIndexPaths:contains(self:getDelegate():getCursorIndexPath()) then
            if self:getDataSource():numberOfItemsInSection(1) > 0 then
                self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
            else
                if self.selectionBackground then
                    self.selectionBackground:setVisible(false)
                    self.selectionBackground:setNeedsLayout()
                    self.selectionBackground:layoutIfNeeded()
                end
            end
        end
    end)
    self.delegate:didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
        local cell = self:getDataSource():cellForItemAtIndexPath(cursorIndexPath)
        if cell then
            self.selectionBackground:setPosition(cell:getPosition().x - self.cursorImageItem:getSize().width - 15, cell:getPosition().y)
            self.selectionBackground:setSize(self.cursorImageItem:getSize().width, self.cursorImageItem:getSize().height)
            self.selectionBackground:setVisible(self:hasFocus())
            self.selectionBackground:setNeedsLayout()
            self.selectionBackground:layoutIfNeeded()
        end
    end)

    return self
end

---
-- Returns the data source associated with the collection view.
--
-- @treturn CollectionViewDataSource The data source.
--
function CollectionView:getDataSource()
    return self.dataSource
end

---
-- Returns the delegate associated with the collection view.
--
-- @treturn CollectionViewDelegate The delegate.
--
function CollectionView:getDelegate()
    return self.delegate
end

---
-- Gets the current value of the `allowsMultipleSelection` property.
--
-- @treturn boolean The current value of `allowsMultipleSelection`.
--
function CollectionView:getAllowsMultipleSelection()
    return self.allowsMultipleSelection
end

---
-- Sets the `allowsMultipleSelection` property to the specified value.
--
-- @tparam boolean allowsMultipleSelection The new value for `allowsMultipleSelection`.
--
function CollectionView:setAllowsMultipleSelection(allowsMultipleSelection)
    self.allowsMultipleSelection = allowsMultipleSelection
end

---
-- Gets the current value of the `allowsCursorSelection` property. If `true` items will be selected
-- when the cursor is next to them.
--
-- @treturn boolean The current value of `allowsCursorSelection`.
--
function CollectionView:getAllowsCursorSelection()
    return self.allowsCursorSelection
end

---
-- Sets the `allowsCursorSelection` property to the specified value.
--
-- @tparam boolean allowsCursorSelection The new value for `allowsCursorSelection`.
--
function CollectionView:setAllowsCursorSelection(allowsCursorSelection)
    self.allowsCursorSelection = allowsCursorSelection
end

---
-- Set a new scroll delta value.
--
-- @tparam number delta The new scroll delta value.
--
function CollectionView:setScrollDelta(delta)
    ScrollView.setScrollDelta(self, delta + self.layout:getItemSpacing())
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function CollectionView:layoutIfNeeded()
    ScrollView.layoutIfNeeded(self)

    self.layout:layoutSubviews(self)
    if self.selectionBackground then
        self.selectionBackground:setVisible(self:hasFocus())
    end
    return true
end

function CollectionView:setHasFocus(hasFocus)
    ScrollView.setHasFocus(self, hasFocus)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function CollectionView:onKeyboardEvent(key, pressed, flags, blocked)
    if not self:isVisible() or blocked then
        return blocked
    end
    if pressed then
        local currentIndexPath = self:getDelegate():getCursorIndexPath()
        if currentIndexPath then
            if key == 208 then
                local nextIndexPath = self:getDataSource():getNextIndexPath(currentIndexPath)
                local cell = self:getDataSource():cellForItemAtIndexPath(nextIndexPath)
                if not cell:isVisible() then
                    self:scrollDown()
                end
                self:getDelegate():setCursorIndexPath(nextIndexPath)
                return true
            elseif key == 200 then
                local nextIndexPath = self:getDataSource():getPreviousIndexPath(currentIndexPath)
                local cell = self:getDataSource():cellForItemAtIndexPath(nextIndexPath)
                if not cell:isVisible() then
                    self:scrollUp()
                end
                self:getDelegate():setCursorIndexPath(nextIndexPath)
                return true
            elseif key == 28 then
                self:getDelegate():selectItemAtIndexPath(self:getDelegate():getCursorIndexPath())
            end
        end
    end
    return L{200, 208}:contains(key)
end

return CollectionView