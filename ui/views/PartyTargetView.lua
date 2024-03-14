local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local PartyTargetView = setmetatable({}, {__index = FFXIWindow })
PartyTargetView.__index = PartyTargetView
PartyTargetView.__type = 'PartyTargetView'

function PartyTargetView.new(target_tracker)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 10, 0, 0))), PartyTargetView)

    self.menuArgs = {}
    self.targets = target_tracker:get_targets()

    self:setScrollDelta(20)
    self:setScrollEnabled(true)
    self:setAllowsCursorSelection(true)

    local itemsToAdd = L{}

    local sectionNum = 1
    local currentRow = 1

    for target in self.targets:it() do
        local item = TextItem.new(target:description(), TextStyle.Default.Text)
        local indexPath = IndexPath.new(sectionNum, currentRow)
        itemsToAdd:append(IndexedItem.new(item, indexPath))
        currentRow = currentRow + 1
    end

    dataSource:addItems(itemsToAdd)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        self.menuArgs['selected_target'] = self.targets[1]
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self.menuArgs['selected_target'] = self.targets[indexPath.row]
    end), self:getDelegate():didSelectItemAtIndexPath())

    return self
end

function PartyTargetView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("View current party targets.")
end

function PartyTargetView:getMenuArgs()
    return self.menuArgs
end

return PartyTargetView