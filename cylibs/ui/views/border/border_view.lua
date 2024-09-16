local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')

local BorderView = setmetatable({}, {__index = CollectionView })
BorderView.__index = BorderView
BorderView.__type = "BorderView"

---
-- Creates a background view with top, middle, and bottom images.
--
-- @param frame The frame for the background view.
-- @param topImagePath The file path of the top image.
-- @param midImagePath The file path of the middle image.
-- @param bottomImagePath The file path of the bottom image.
-- @treturn BackgroundView The created background view.
--
function BorderView.new(frame, resizableImageItem)
    local self = setmetatable(CollectionView.new(CollectionViewDataSource.new(), HorizontalFlowLayout.new(0), nil, CollectionView.defaultBackgroundStyle()), BorderView)

    self.borderImageItem = resizableImageItem

    self:getDataSource().cellForItem = function(item, _)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(item:getSize().width)
        return cell
    end

    self:getDisposeBag():add(self.dataSource:onItemsChanged():addAction(function(_, _, updatedIndexPaths)
        for indexPath in updatedIndexPaths:it() do
            local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
            if cell then
                cell:setItemSize(self:getSize().height)
            end
        end
    end, self.dataSource:onItemsChanged()))

    self:setVisible(false)
    self:setSize(frame.width, frame.height)

    return self
end

function BorderView:setSize(width, height)
    if self.frame.width == width and self.frame.height == height then
        return
    end
    CollectionView.setSize(self, width, height)

    local rowIndex = 0
    local imageItems = self:getImageItems(Frame.new(0, 0, width, height)):map(function(item)
        rowIndex = rowIndex + 1
        return IndexedItem.new(item, IndexPath.new(1, rowIndex))
    end)

    self:getDataSource():updateItems(imageItems)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function BorderView:getImageItems(frame)
    local leftImageItem = self.borderImageItem:getImageItem(ResizableImageItem.Left)
    local rightImageItem = self.borderImageItem:getImageItem(ResizableImageItem.Right)

    local centerBorderWidth = frame.width - leftImageItem:getSize().width - rightImageItem:getSize().width
    local centerImageItem = self.borderImageItem:getImageItem(ResizableImageItem.Center)

    centerImageItem = ImageItem.new(
            centerImageItem:getImagePath(),
            centerBorderWidth,
            centerImageItem:getSize().height
    )
    centerImageItem:setRepeat(centerBorderWidth / centerImageItem:getSize().width, 1)

    local imageItems = L{ leftImageItem, centerImageItem, rightImageItem }:map(function(imageItem)
        imageItem:setAlpha(225)
        return imageItem
    end)
    return imageItems
end

function BorderView:hitTest(x, y)
    return false
end

return BorderView