local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local MessageView = setmetatable({}, {__index = CollectionView })
MessageView.__index = MessageView

function MessageView.new(title, header, message, footer, viewSize)
    local _, numLines = message:gsub('\n', '\n')

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        if L{ 1 }:contains(indexPath.row) then
            cell:setItemSize(20)
        elseif L{ 3 }:contains(indexPath.row) then
            cell:setItemSize(20)
            cell:setUserInteractionEnabled(true)
        else
            cell:setItemSize(numLines * 20 - 10)
        end
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), MessageView)

    self.title = title

    self:setScrollEnabled(false)

    local itemsToAdd = L{}

    itemsToAdd:append(IndexedItem.new(TextItem.new(header, TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    itemsToAdd:append(IndexedItem.new(TextItem.new(message, TextStyle.Default.TextSmall), IndexPath.new(1, 2)))
    itemsToAdd:append(IndexedItem.new(TextItem.new(footer, TextStyle.Default.HeaderSmall), IndexPath.new(1, 3)))

    dataSource:addItems(itemsToAdd)

    return self
end

function MessageView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle(self.title)
end

return MessageView