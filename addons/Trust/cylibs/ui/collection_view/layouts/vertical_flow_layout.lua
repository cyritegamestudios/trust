local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')

local VerticalFlowLayout = {}
VerticalFlowLayout.__index = VerticalFlowLayout

function VerticalFlowLayout.new(itemSpacing, padding, sectionSpacing)
    local self = setmetatable({}, VerticalFlowLayout)
    self.itemSpacing = itemSpacing or 0
    self.sectionSpacing = sectionSpacing or 0
    self.padding = padding or Padding.equal(0)
    return self
end

function VerticalFlowLayout:destroy()
end

-- Add a function to determine the size of a cell
function VerticalFlowLayout:sizeForItemAtIndexPath(collectionView, cell)
    -- You can implement your logic here to calculate the size of the cell
    -- For simplicity, we'll assume a fixed cell width and use cell:getHeight() for height.
    return { width = collectionView:getSize().width, height = cell:getItemSize() }  -- Adjust as needed
end

function VerticalFlowLayout:layoutSubviews(collectionView)
    local yOffset = self.padding.top
    for section = 1, collectionView:getDataSource():numberOfSections() do
        local numberOfItems = collectionView:getDataSource():numberOfItemsInSection(section)

        for row = 1, numberOfItems do
            local indexPath = IndexPath.new(section, row)
            local item = collectionView:getDataSource():itemAtIndexPath(indexPath)

            local cell = collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
            cell:setItem(item)

            collectionView:addSubview(cell)

            local cellSize = self:sizeForItemAtIndexPath(collectionView, cell)

            -- Set position and size of the cell
            cell:setPosition(self.padding.left, yOffset)
            cell:setSize(cellSize.width - self.padding.left - self.padding.right, cellSize.height)
            cell:layoutIfNeeded()

            yOffset = yOffset + cellSize.height + self.itemSpacing
        end

        yOffset = yOffset + self.sectionSpacing
    end

    -- Set the width and height of the layout
    self.width = collectionView:getSize().width
    self.height = yOffset
end

function VerticalFlowLayout:setNeedsLayout(collectionView, addedIndexPaths, removedIndexPaths, updatedIndexPaths)
    local totalChanges = #addedIndexPaths + #removedIndexPaths
    if totalChanges >= 0 then
        self:layoutSubviews(collectionView)
        return
    end

    local x, y = collectionView:getPosition()
    local yOffset = y

    for section = 1, collectionView.dataSource:numberOfSections() do
        local numberOfItems = collectionView:getDataSource():numberOfItemsInSection(section)

        for row = 1, numberOfItems do
            local currentIndexPath = IndexPath.new(section, row)
            local cell = collectionView:getDataSource():cellForItemAtIndexPath(currentIndexPath)

            -- Determine the size of the cell
            local cellSize = self:sizeForItemAtIndexPath(collectionView, cell)

            -- If the cell was added or removed, adjust the yOffset
            local shouldReposition = false

            for _, addedIndexPath in ipairs(addedIndexPaths) do
                if addedIndexPath.section == currentIndexPath.section and addedIndexPath.row <= currentIndexPath.row then
                    shouldReposition = true
                    break
                end
            end

            for _, removedIndexPath in ipairs(removedIndexPaths) do
                if removedIndexPath.section == currentIndexPath.section and removedIndexPath.row < currentIndexPath.row then
                    shouldReposition = true
                    break
                end
            end

            if shouldReposition then
                -- Set position and size of the cell
                cell:setPosition(x, yOffset)
                cell:setSize(cellSize.width, cellSize.height)
            end

            yOffset = yOffset + cellSize.height
        end
        yOffset = yOffset + self.sectionSpacing
    end

    -- Set the width and height of the layout
    self.width = collectionView:getWidth()
    self.height = yOffset
end

return VerticalFlowLayout
