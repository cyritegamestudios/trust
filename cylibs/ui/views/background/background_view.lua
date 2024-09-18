local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local BackgroundView = setmetatable({}, {__index = CollectionView })
BackgroundView.__index = BackgroundView
BackgroundView.__type = "BackgroundView"


---
-- Creates a background view with top, middle, and bottom images.
--
-- @param frame The frame for the background view.
-- @param topImagePath The file path of the top image.
-- @param midImagePath The file path of the middle image.
-- @param bottomImagePath The file path of the bottom image.
-- @treturn BackgroundView The created background view.
--
function BackgroundView.new(frame, topImagePath, midImagePath, bottomImagePath)
    local borderSize = 10

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageCollectionViewCell.new(item)
        if L{ 1, 3 }:contains(indexPath.row) then
            cell:setItemSize(borderSize)
        else
            cell:setItemSize(frame.height - 2 * borderSize)
        end
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0)), CollectionView)

    self:setSize(frame.width, frame.height)
    self:setScrollEnabled(false)

    local topItem = ImageItem.new(topImagePath, frame.width, borderSize)
    topItem:setRepeat(1, 1)
    topItem:setAlpha(225)

    local midItem = ImageItem.new(midImagePath, frame.width, frame.width - 2 * borderSize)
    midItem:setRepeat(1, frame.height / 4 - 2)
    midItem:setAlpha(225)

    local bottomItem = ImageItem.new(bottomImagePath, frame.width, borderSize)
    bottomItem:setRepeat(1, 1)
    bottomItem:setAlpha(225)

    dataSource:addItem(topItem, IndexPath.new(1, 1))
    dataSource:addItem(midItem, IndexPath.new(1, 2))
    dataSource:addItem(bottomItem, IndexPath.new(1, 3))

    self:setVisible(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function BackgroundView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end
    -- TODO: 2023-09-14 add support for resizing backgrounds after init
    return true
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function BackgroundView:hitTest(x, y)
    return false
end

return BackgroundView