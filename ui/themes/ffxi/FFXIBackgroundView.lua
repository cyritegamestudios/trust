local BorderView = require('cylibs/ui/views/border/border_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TitleBorderView = require('cylibs/ui/views/border/title_border_view')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIBackgroundView = setmetatable({}, {__index = CollectionView })
FFXIBackgroundView.__index = FFXIBackgroundView
FFXIBackgroundView.__type = "FFXIBackgroundView"

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

function FFXIBackgroundView:onSelectTitle()
    return self.selectTitle
end

---
-- Creates a background view with top, middle, and bottom images.
--
-- @param frame The frame for the background view.
-- @param topImagePath The file path of the top image.
-- @param midImagePath The file path of the middle image.
-- @param bottomImagePath The file path of the bottom image.
-- @treturn BackgroundView The created background view.
--
function FFXIBackgroundView.new(frame, hideTitle)
    local style = FFXIClassicStyle.background()

    local self = setmetatable(CollectionView.new(CollectionViewDataSource.new(), VerticalFlowLayout.new(0), nil, style), FFXIBackgroundView)

    self.selectTitle = Event.newEvent()
    self.borderViews = L{}

    self:getDataSource().cellForItem = function(item, _)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(self:getSize().height)
        cell:setUserInteractionEnabled(true)
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

    borderImageItem:setImageItem(style:getBorderLeftItem(), ResizableImageItem.Left)
    borderImageItem:setImageItem(style:getBorderCenterItem(), ResizableImageItem.Center)
    borderImageItem:setImageItem(style:getBorderRightItem(), ResizableImageItem.Right)

    if not hideTitle then
        self.topBorderView = TitleBorderView.new(Frame.new(0, 0, frame.width, 3), borderImageItem)
    else
        self.topBorderView = BorderView.new(Frame.new(0, 0, frame.width, 3), borderImageItem)
    end
    self.topBorderView:setVisible(false)

    self:addSubview(self.topBorderView)

    self.bottomBorderView = BorderView.new(Frame.new(0, 0, frame.width, 3), borderImageItem)
    self.bottomBorderView:setVisible(false)

    self:addSubview(self.bottomBorderView)

    self.borderViews = L{ self.topBorderView, self.bottomBorderView }

    self:getDisposeBag():add(self.topBorderView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self.topBorderView:getDelegate():deselectAllItems()
        self:onSelectTitle():trigger(self)
    end), self.topBorderView:getDelegate():didSelectItemAtIndexPath())

    return self
end

function FFXIBackgroundView:updateBorder()

end

function FFXIBackgroundView:destroy()
    CollectionView.destroy(self)

    self.selectTitle:removeAllActions()
end

function FFXIBackgroundView:setTitle(title, size)
    self.topBorderView:setTitle(title, size)
end

function FFXIBackgroundView:setSize(width, height)
    if self.frame.width == width and self.frame.height == height then
        return
    end
    CollectionView.setSize(self, width, height)

    for borderView in self.borderViews:it() do
        borderView:setSize(width, 3)
    end

    self:getDataSource():updateItem(self:getImageItem(self.frame), IndexPath.new(1, 1))

    self:layoutIfNeeded()
end

function FFXIBackgroundView:getImageItem(frame)
    local imageItem = ImageItem.new(
            self.style:getBackgroundItem():getImagePath(),
            self.style:getBackgroundItem():getSize().width,
            self.style:getBackgroundItem():getSize().height
    )
    imageItem:setRepeat(frame.width / imageItem:getSize().width, frame.height / imageItem:getSize().height)
    imageItem:setAlpha(225)

    return imageItem
end

function FFXIBackgroundView:setEditing(editing)
    CollectionView.setEditing(self, editing)

    for border in L{ self.topBorderView, self.bottomBorderView }:it() do
        border:setEditing(editing)
    end
end

function FFXIBackgroundView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self)
            or not self.topBorderView or not self.bottomBorderView then
        return
    end

    self.topBorderView:setVisible(self:isVisible())
    self.topBorderView:setPosition(0, -self.topBorderView:getSize().height / 2 + 1)
    self.topBorderView:layoutIfNeeded()

    self.bottomBorderView:setVisible(self:isVisible())
    self.bottomBorderView:setPosition(0, self:getSize().height - 1)
    self.bottomBorderView:layoutIfNeeded()
end

function FFXIBackgroundView:hitTest(x, y)
    return false
end

return FFXIBackgroundView