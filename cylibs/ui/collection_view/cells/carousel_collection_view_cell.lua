local ImageView = require('cylibs/ui/image_view')

local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')

local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local CarouselCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
CarouselCollectionViewCell.__index = CarouselCollectionViewCell
CarouselCollectionViewCell.__type = "CarouselCollectionViewCell"


function CarouselCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), CarouselCollectionViewCell)

    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(16)
        cell:setIsSelectable(false)
        cell:setUserInteractionEnabled(false)
        return cell
    end)
    self.carouselView = CollectionView.new(dataSource, HorizontalFlowLayout.new(2), nil, CollectionViewStyle.empty())
    self.carouselView:setScrollEnabled(false)
    self.carouselView:setAllowsCursorSelection(false)

    self:addSubview(self.carouselView)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function CarouselCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    self.carouselView:getDataSource():removeAllItems()
    self.carouselView:getDataSource():addItems(IndexedItem.fromItems(item:getImageItems(), 1))

    self.carouselView:setNeedsLayout()
    self.carouselView:layoutIfNeeded()
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function CarouselCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    self.carouselView:setSize(self:getSize().width, self:getSize().height)

    return true
end

return CarouselCollectionViewCell