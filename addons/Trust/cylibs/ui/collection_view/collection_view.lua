local CollectionViewDelegate = require('cylibs/ui/collection_view/collection_view_delegate')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local Frame = require('cylibs/ui/views/frame')
local ScrollView = require('cylibs/ui/scroll_view/scroll_view')

local CollectionView = setmetatable({}, {__index = ScrollView })
CollectionView.__index = CollectionView

---
-- Creates a new CollectionView instance with the specified data source and layout.
--
-- @tparam CollectionViewDataSource dataSource The data source providing content for the collection view.
-- @tparam CollectionViewLayout layout The layout strategy for arranging items in the collection view.
-- @tparam CollectionViewDelegate delegate (optional) The delegate for interacting with items in the collection view.
-- @treturn CollectionView The newly created CollectionView instance.
--
function CollectionView.new(dataSource, layout, delegate, selectionImageItem)
    local self = setmetatable(ScrollView.new(Frame.zero()), CollectionView)

    self.layout = layout
    self.dataSource = dataSource
    self.delegate = delegate or CollectionViewDelegate.new(self)
    self.allowsMultipleSelection = false

    if selectionImageItem then
        self.selectionBackground = ImageCollectionViewCell.new(selectionImageItem)

        self:getContentView():addSubview(self.selectionBackground)

        self:getDisposeBag():addAny(L{ self.selectionBackground })

        self.delegate:didSelectItemAtIndexPath():addAction(function(indexPath)
            if not self.allowsMultipleSelection then
                local cell = self.dataSource:cellForItemAtIndexPath(indexPath)
                if cell then
                    self.selectionBackground:setPosition(cell:getPosition().x, cell:getPosition().y)
                    self.selectionBackground:setSize(selectionImageItem:getSize().width, selectionImageItem:getSize().height)
                    self.selectionBackground:setNeedsLayout()
                    self.selectionBackground:layoutIfNeeded()
                end
            end
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
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function CollectionView:layoutIfNeeded()
    ScrollView.layoutIfNeeded(self)
    self.layout:layoutSubviews(self)
    return true
end

return CollectionView