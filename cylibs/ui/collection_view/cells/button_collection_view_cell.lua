local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageView = require('cylibs/ui/image_view')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')

local ButtonCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ButtonCollectionViewCell.__index = ButtonCollectionViewCell


function ButtonCollectionViewCell.new(buttonItem)
    local self = setmetatable(CollectionViewCell.new(buttonItem), ButtonCollectionViewCell)

    self:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(item:getSize().width)
        return cell
    end)

    self.textView = TextCollectionViewCell.new(buttonItem:getTextItem())
    self.textView:setEstimatedSize(18)
    self.textView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    self:addSubview(self.textView)

    self.buttonView = CollectionView.new(dataSource, HorizontalFlowLayout.new())
    self.buttonView:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    self:addSubview(self.buttonView)

    local items = L{
        IndexedItem.new(buttonItem:getImageItems().left, IndexPath.new(1, 1)),
        IndexedItem.new(buttonItem:getImageItems().center, IndexPath.new(1, 2)),
        IndexedItem.new(buttonItem:getImageItems().right, IndexPath.new(1, 3)),
    }
    self.buttonView:getDataSource():addItems(items)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ButtonCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ButtonCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    self.textView:setPosition(10, self.textView:getPosition().y)
    self.textView:setSize(self:getSize().width, self:getSize().height)
    self.textView:layoutIfNeeded()

    self.buttonView:setSize(self:getSize().width, self:getSize().height)
    self.buttonView:layoutIfNeeded()

    return true
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function ButtonCollectionViewCell:hitTest(x, y)
    return self.buttonView:hitTest(x, y)
end

return ButtonCollectionViewCell