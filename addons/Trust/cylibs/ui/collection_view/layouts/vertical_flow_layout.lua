local Button = require('cylibs/ui/button')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')

local VerticalFlowLayout = {}
VerticalFlowLayout.__index = VerticalFlowLayout

function VerticalFlowLayout.new(itemSpacing, padding, sectionSpacing)
    local self = setmetatable({}, VerticalFlowLayout)

    self.disposeBag = DisposeBag.new()
    self.itemSpacing = itemSpacing or 0
    self.sectionSpacing = sectionSpacing or 0
    self.padding = padding or Padding.equal(0)
    self.scrollEnabled = false

    return self
end

function VerticalFlowLayout:destroy()
    self.disposeBag:destroy()
end

-- Add a function to determine the size of a cell
function VerticalFlowLayout:sizeForItemAtIndexPath(collectionView, cell)
    -- You can implement your logic here to calculate the size of the cell
    -- For simplicity, we'll assume a fixed cell width and use cell:getHeight() for height.
    return { width = collectionView:getSize().width, height = cell:getItemSize() }  -- Adjust as needed
end

local num_layout_called = 0

function VerticalFlowLayout:layoutSubviews(collectionView)
    num_layout_called = num_layout_called + 1

    local yOffset = self.padding.top
    for section = 1, collectionView:getDataSource():numberOfSections() do
        local numberOfItems = collectionView:getDataSource():numberOfItemsInSection(section)

        for row = 1, numberOfItems do
            local indexPath = IndexPath.new(section, row)
            local item = collectionView:getDataSource():itemAtIndexPath(indexPath)

            local cell = collectionView:getDataSource():cellForItemAtIndexPath(indexPath)
            cell:setItem(item)

            collectionView:getContentView():addSubview(cell)

            local cellSize = self:sizeForItemAtIndexPath(collectionView, cell)

            -- Set position and size of the cell
            cell:setPosition(self.padding.left, yOffset)
            cell:setSize(cellSize.width - self.padding.left - self.padding.right, cellSize.height)
            cell:setVisible(collectionView:getContentView():isVisible())
            cell:layoutIfNeeded()

            yOffset = yOffset + cellSize.height + self.itemSpacing
        end

        yOffset = yOffset + self.sectionSpacing
    end

    -- Set the width and height of the layout
    self.width = collectionView:getSize().width
    self.height = yOffset

    if not self.scrollEnabled then
        collectionView:setSize(self.width, self.height)
    else
        local offset = 40
        self.upArrow:setPosition(collectionView.frame.width - offset, offset)
        self.downArrow:setPosition(collectionView.frame.width - offset, collectionView.frame.height - offset)

        self.upArrow:layoutIfNeeded()
        self.downArrow:layoutIfNeeded()

        collectionView:updateContentView()
    end
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

function VerticalFlowLayout:enableScrolling(collectionView)
    if self.scrollEnabled then
        return
    end
    self.scrollEnabled = true

    self.upArrow = Button.new("▲", 20, 20)
    self.upArrow:setVisible(false)

    self.downArrow = Button.new("▼", 20, 20)
    self.downArrow:setVisible(false)

    self.disposeBag:addAny(L{ self.upArrow, self.downArrow })

    collectionView:addSubview(self.upArrow)
    collectionView:addSubview(self.downArrow)

    self.disposeBag:add(self.upArrow:onClick():addAction(function(_, _, _)
        collectionView:setContentOffset(math.max(collectionView:getContentOffset().x, -self.width), math.max(collectionView:getContentOffset().y - 10, -self.height / 2))
    end), self.upArrow:onClick())

    self.disposeBag:add(self.downArrow:onClick():addAction(function(_, _, _)
        collectionView:setContentOffset(math.min(collectionView:getContentOffset().x, 0), math.min(collectionView:getContentOffset().y + 10, 0))
    end), self.downArrow:onClick())

    self:layoutSubviews(collectionView)
end

return VerticalFlowLayout
