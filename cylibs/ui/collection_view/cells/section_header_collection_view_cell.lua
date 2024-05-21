local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
local ContainerCollectionViewCell = require('cylibs/ui/collection_view/cells/container_collection_view_cell')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local ViewItem = require('cylibs/ui/collection_view/items/view_item')

local SectionHeaderCollectionViewCell = setmetatable({}, {__index = ContainerCollectionViewCell })
SectionHeaderCollectionViewCell.__index = SectionHeaderCollectionViewCell
SectionHeaderCollectionViewCell.__type = "SectionHeaderCollectionViewCell"

function SectionHeaderCollectionViewCell.new(item)
    local sectionSize = item:getSectionSize()

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell
        if item.__type == ImageItem.__type then
            cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(item:getSize().height)
            cell:setScaleToFitParent(false)
        elseif item.__type == TextItem.__type then
            cell = TextCollectionViewCell.new(item)
            cell:setItemSize(sectionSize)
        end
        cell:setUserInteractionEnabled(false)
        cell:setIsSelectable(false)
        return cell
    end)

    local sectionHeaderView = CollectionView.new(dataSource, HorizontalFlowLayout.new(4, Padding.new(0, 0, 0, 0)), nil, CollectionViewStyle.empty())

    local self = setmetatable(ContainerCollectionViewCell.new(ViewItem.new(sectionHeaderView, false)), SectionHeaderCollectionViewCell)

    self.sectionHeaderView = sectionHeaderView

    self:setItem(item)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SectionHeaderCollectionViewCell:destroy()
    ContainerCollectionViewCell.destroy(self)
end

function SectionHeaderCollectionViewCell:setItem(item)
    self.sectionHeaderView:getDataSource():removeAllItems()

    self.sectionHeaderView:getDataSource():addItems(L{
        IndexedItem.new(item:getImageItem(), IndexPath.new(1, 1)),
        IndexedItem.new(item:getTitleItem(), IndexPath.new(1, 2))
    })
    self.sectionHeaderView:setNeedsLayout()
    self.sectionHeaderView:layoutIfNeeded()

    ContainerCollectionViewCell.setItem(self, self:getItem())
end

return SectionHeaderCollectionViewCell