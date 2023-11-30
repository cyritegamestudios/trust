local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local PartyTargetView = setmetatable({}, {__index = CollectionView })
PartyTargetView.__index = PartyTargetView
PartyTargetView.__type = 'PartyTargetView'

function PartyTargetView.new(target_tracker)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), PartyTargetView)

    local itemsToAdd = L{}

    local sectionNum = 1
    local currentRow = 1

    for target in target_tracker:get_targets():it() do
        local item = TextItem.new(target:description(), TextStyle.Default.Text)
        local indexPath = IndexPath.new(sectionNum, currentRow)
        itemsToAdd:append(IndexedItem.new(item, indexPath))
        currentRow = currentRow + 1
    end

    dataSource:addItems(itemsToAdd)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PartyTargetView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("View current party targets.")
end

return PartyTargetView