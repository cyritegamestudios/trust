local Alignment = require('cylibs/ui/layout/alignment')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local TitleBorderView = setmetatable({}, {__index = CollectionView })
TitleBorderView.__index = TitleBorderView

TitleBorderView.HeaderSmall = TextStyle.new(
        Color.yellow,
        Color.clear,
        "Arial",
        8,
        Color.white:withAlpha(175),
        Color.lightGrey,
        0,
        0.5,
        Color.new(125, 180, 180, 200),
        true,
        Color.white:withAlpha(175),
        true
)

---
-- Creates a background view with top, middle, and bottom images.
--
-- @param frame The frame for the background view.
-- @param topImagePath The file path of the top image.
-- @param midImagePath The file path of the middle image.
-- @param bottomImagePath The file path of the bottom image.
-- @treturn BackgroundView The created background view.
--
function TitleBorderView.new(frame, resizableImageItem)
    local self = setmetatable(CollectionView.new(CollectionViewDataSource.new(), HorizontalFlowLayout.new(0), nil, CollectionView.defaultBackgroundStyle()), TitleBorderView)

    self.borderImageItem = resizableImageItem
    self.title = ""

    self:getDataSource().cellForItem = function(item, _)
        if item.__type == ImageItem.__type then
            local cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(item:getSize().width)
            return cell
        else
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(self.centerBorderWidth)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end

    self:setVisible(false)
    self:setSize(frame.width, frame.height)
    self:setScrollEnabled(false)

    return self
end

function TitleBorderView:setTitle(title, size)
    if self.title == title then
        return
    end
    self.title = title

    local centerTextItem = TextItem.new(self.title, TitleBorderView.HeaderSmall)

    centerTextItem:setOffset(0, -4)
    centerTextItem:setHorizontalAlignment(Alignment.center())

    if size then
        centerTextItem:setSize(size.width, size.height)
    end

    self:getDataSource():updateItem(centerTextItem, IndexPath.new(1, 3))
end

function TitleBorderView:setSize(width, height)
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

function TitleBorderView:getImageItems(frame)
    local leftImageItem = self.borderImageItem:getImageItem(ResizableImageItem.Left)
    local rightImageItem = self.borderImageItem:getImageItem(ResizableImageItem.Right)

    local leftImageItem1 = ImageItem.new(
            leftImageItem:getImagePath(),
            leftImageItem:getSize().width,
            leftImageItem:getSize().height
    )
    local leftImageItem2 = ImageItem.new(
            rightImageItem:getImagePath(),
            rightImageItem:getSize().width,
            rightImageItem:getSize().height
    )

    local rightImageItem1 = ImageItem.new(
            leftImageItem:getImagePath(),
            leftImageItem:getSize().width,
            leftImageItem:getSize().height
    )
    local rightImageItem2 = ImageItem.new(
            rightImageItem:getImagePath(),
            rightImageItem:getSize().width,
            rightImageItem:getSize().height
    )

    self.centerBorderWidth = frame.width - 2 * leftImageItem:getSize().width - 2 * rightImageItem:getSize().width

    local centerTextItem = TextItem.new(self.title, TitleBorderView.HeaderSmall)
    centerTextItem:setOffset(0, -4)
    centerTextItem:setHorizontalAlignment(Alignment.center())

    local imageItems = L{ leftImageItem1, leftImageItem2, centerTextItem, rightImageItem1, rightImageItem2 }:map(function(imageItem)
        return imageItem
    end)
    return imageItems
end

function TitleBorderView:setEditing(editing)
    CollectionView.setEditing(self, editing)

    local cell = self:getDataSource():cellForItemAtIndexPath(IndexPath.new(1, 3))
    if cell then
        if editing then
            cell:setVisible(false)
        else
            cell:setVisible(true)
        end
        cell:layoutIfNeeded()
    end
end

function TitleBorderView:hitTest(x, y)
    return false
end

return TitleBorderView