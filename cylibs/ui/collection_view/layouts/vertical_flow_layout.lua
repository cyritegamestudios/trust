local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SectionHeaderCollectionViewCell = require('cylibs/ui/collection_view/cells/section_header_collection_view_cell')

local VerticalFlowLayout = {}
VerticalFlowLayout.__index = VerticalFlowLayout

function VerticalFlowLayout.new(itemSpacing, padding, sectionSpacing, sizeForItem)
    local self = setmetatable({}, VerticalFlowLayout)

    self.disposeBag = DisposeBag.new()
    self.itemSpacing = itemSpacing or 0
    self.sectionSpacing = sectionSpacing or 0
    self.padding = padding or Padding.equal(0)

    return self
end

function VerticalFlowLayout:destroy()
    self.disposeBag:destroy()
end

-- Add a function to determine the size of a cell
function VerticalFlowLayout:sizeForItemAtIndexPath(collectionView, cell)
    return { width = collectionView:getSize().width, height = cell:getItemSize() }
end

local num_layout_called = 0

function VerticalFlowLayout:layoutSubviews(collectionView, indexPathFilter)
    num_layout_called = num_layout_called + 1

    if indexPathFilter == nil then
        indexPathFilter = function (_)
            return true
        end
    end
    local yOffset = self.padding.top
    for section = 1, collectionView:getDataSource():numberOfSections() do
        local numberOfItems = collectionView:getDataSource():numberOfItemsInSection(section)

        local sectionHeaderItem = collectionView:getDataSource():headerItemForSection(section)
        if sectionHeaderItem then
            local sectionHeaderCell = collectionView:getDataSource():headerViewForSection(section)
            if sectionHeaderCell then
                sectionHeaderCell:setItem(sectionHeaderItem)

                collectionView:getContentView():addSubview(sectionHeaderCell)

                local cellSize = { width = collectionView:getSize().width, height = sectionHeaderItem:getSectionSize() }

                sectionHeaderCell:setPosition(self.padding.left, yOffset)
                sectionHeaderCell:setSize(cellSize.width - self.padding.left - self.padding.right, cellSize.height)
                sectionHeaderCell:setVisible(collectionView:getContentView():isVisible() and sectionHeaderCell:isVisible())
                sectionHeaderCell:layoutIfNeeded()

                yOffset = yOffset + cellSize.height + 2
            end
        end

        for row = 1, numberOfItems do
            local indexPath = IndexPath.new(section, row)
            local item = collectionView:getDataSource():itemAtIndexPath(indexPath)
            local cell = collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
            local cellSize = self:sizeForItemAtIndexPath(collectionView, cell)
            if indexPathFilter(indexPath) then
                cell:setItem(item)

                collectionView:getContentView():addSubview(cell)

                cellSize = self:sizeForItemAtIndexPath(collectionView, cell)

                -- Set position and size of the cell
                cell:setPosition(self.padding.left, yOffset)
                cell:setSize(cellSize.width - self.padding.left - self.padding.right, cellSize.height)
                cell:setVisible(collectionView:getContentView():isVisible() and cell:isVisible())
                cell:layoutIfNeeded()
            end

            yOffset = yOffset + cellSize.height + self.itemSpacing
        end

        yOffset = yOffset + self.sectionSpacing
    end

    -- Set the width and height of the layout
    self.width = collectionView:getSize().width
    self.height = yOffset + self.padding.bottom

    collectionView:setContentSize(self.width, self.height)
end

function VerticalFlowLayout:setNeedsLayout(collectionView, addedIndexPaths, removedIndexPaths, updatedIndexPaths)
    if #addedIndexPaths + #removedIndexPaths + #updatedIndexPaths == 0 then
        return
    end
    if #addedIndexPaths + #removedIndexPaths == 0 then
        self:layoutSubviews(collectionView, function(indexPath)
            return updatedIndexPaths:contains(indexPath)
        end)
    else
        self:layoutSubviews(collectionView)
    end
end

function VerticalFlowLayout:getItemSpacing()
    return self.itemSpacing
end

function VerticalFlowLayout:getPadding()
    return self.padding
end

return VerticalFlowLayout
