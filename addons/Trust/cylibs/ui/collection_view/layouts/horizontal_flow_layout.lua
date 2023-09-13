local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')

local HorizontalFlowLayout = {}
HorizontalFlowLayout.__index = HorizontalFlowLayout

function HorizontalFlowLayout.new(itemSpacing, padding, sectionSpacing)
    local self = setmetatable({}, HorizontalFlowLayout)
    self.itemSpacing = itemSpacing or 0
    self.padding = padding or Padding.equal(0)
    self.sectionSpacing = sectionSpacing or 0
    self.scrollEnabled = false
    return self
end

function HorizontalFlowLayout:destroy()
end

function HorizontalFlowLayout:sizeForItemAtIndexPath(collectionView, cell)
    return { width = cell:getItemSize(), height = collectionView:getSize().height }
end

function HorizontalFlowLayout:layoutSubviews(collectionView)
    local xOffset = self.padding.left
    for section = 1, collectionView:getDataSource():numberOfSections() do
        local numberOfItems = collectionView:getDataSource():numberOfItemsInSection(section)

        for row = 1, numberOfItems do
            local indexPath = IndexPath.new(section, row)
            local item = collectionView:getDataSource():itemAtIndexPath(indexPath)

            local cell = collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
            cell:setItem(item)

            collectionView:getContentView():addSubview(cell)

            local cellSize = self:sizeForItemAtIndexPath(collectionView, cell)

            cell:setPosition(xOffset, self.padding.top)
            cell:setSize(cellSize.width, cellSize.height - self.padding.top - self.padding.bottom)
            cell:setVisible(collectionView:getContentView():isVisible())
            cell:layoutIfNeeded()

            xOffset = xOffset + cellSize.width + self.itemSpacing
        end
        xOffset = xOffset + self.sectionSpacing
    end

    self.width = xOffset + self.padding.right
    self.height = collectionView:getSize().height

    collectionView:setSize(self.width, self.height)
end

function HorizontalFlowLayout:setNeedsLayout(collectionView, addedIndexPaths, removedIndexPaths, updatedIndexPaths)
    local totalChanges = #addedIndexPaths + #removedIndexPaths
    if totalChanges >= 0 then
        self:layoutSubviews(collectionView)
        return
    end

    local x, y = collectionView:getPosition()
    local xOffset = x

    for section = 1, collectionView:getDataSource():numberOfSections() do
        local numberOfItems = collectionView:getDataSource():numberOfItemsInSection(section)

        for row = 1, numberOfItems do
            local currentIndexPath = IndexPath.new(section, row)
            local cell = collectionView:getDataSource():cellForItemAtIndexPath(currentIndexPath)

            local cellSize = self:sizeForItemAtIndexPath(collectionView, cell)

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
                cell:setPosition(xOffset, y)
                cell:setSize(cellSize.width, cellSize.height)
            end

            xOffset = xOffset + cellSize.width
        end
    end

    self.width = xOffset
    self.height = collectionView:getSize().height
end

function HorizontalFlowLayout:enableScrolling(collectionView)
    if self.scrollEnabled then
        return
    end
    self.scrollEnabled = true
end

return HorizontalFlowLayout
