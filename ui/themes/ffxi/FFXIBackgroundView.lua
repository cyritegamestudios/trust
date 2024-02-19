local BorderView = require('cylibs/ui/views/border/border_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TitleBorderView = require('cylibs/ui/views/border/title_border_view')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIBackgroundView = setmetatable({}, {__index = CollectionView })
FFXIBackgroundView.__index = FFXIBackgroundView

FFXIBackgroundView.CenterImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_background.png',
        60,
        4
)

FFXIBackgroundView.Border = {}
FFXIBackgroundView.Border.LeftImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_border_left.png',
        20,
        3
)
FFXIBackgroundView.Border.CenterImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_border_middle.png',
        20,
        3
)
FFXIBackgroundView.Border.RightImageItem = ImageItem.new(
        windower.addon_path..'assets/backgrounds/window_border_right.png',
        20,
        3
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
function FFXIBackgroundView.new(frame)
    local self = setmetatable(CollectionView.new(CollectionViewDataSource.new(), VerticalFlowLayout.new(0)), FFXIBackgroundView)

    self:getDataSource().cellForItem = function(item, _)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(self:getSize().height)
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
    self:setScrollEnabled(false)

    local borderImageItem = ResizableImageItem.new()

    borderImageItem:setImageItem(FFXIBackgroundView.Border.LeftImageItem, ResizableImageItem.Left)
    borderImageItem:setImageItem(FFXIBackgroundView.Border.CenterImageItem, ResizableImageItem.Center)
    borderImageItem:setImageItem(FFXIBackgroundView.Border.RightImageItem, ResizableImageItem.Right)

    self.topBorderView = TitleBorderView.new(Frame.new(0, 0, frame.width, 3), borderImageItem)
    self.topBorderView:setVisible(true)

    self:addSubview(self.topBorderView)

    self.bottomBorderView = BorderView.new(Frame.new(0, 0, frame.width, 3), borderImageItem)
    self.bottomBorderView:setVisible(true)

    self:addSubview(self.bottomBorderView)

    return self
end

function FFXIBackgroundView:setTitle(title)
    self.topBorderView:setTitle(title)
end

function FFXIBackgroundView:setSize(width, height)
    if self.frame.width == width and self.frame.height == height then
        return
    end
    CollectionView.setSize(self, width, height)

    self:getDataSource():updateItem(self:getImageItem(self.frame), IndexPath.new(1, 1))

    self:layoutIfNeeded()
end

function FFXIBackgroundView:getImageItem(frame)
    local imageItem = ImageItem.new(
            FFXIBackgroundView.CenterImageItem:getImagePath(),
            FFXIBackgroundView.CenterImageItem:getSize().width,
            FFXIBackgroundView.CenterImageItem:getSize().height
    )
    imageItem:setRepeat(frame.width / imageItem:getSize().width, frame.height / imageItem:getSize().height)
    imageItem:setAlpha(225)

    return imageItem
end

function FFXIBackgroundView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return
    end

    if self.topBorderView and self.bottomBorderView then
        self.topBorderView:setPosition(0, -self.topBorderView:getSize().height / 2 + 1)
        self.bottomBorderView:setPosition(0, self:getSize().height - 1)

        self.topBorderView:setNeedsLayout()
        self.topBorderView:layoutIfNeeded()
    end
end

function FFXIBackgroundView:hitTest(x, y)
    return false
end

return FFXIBackgroundView