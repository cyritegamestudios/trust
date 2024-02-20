local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local InfoBarCollectionViewCell = require('cylibs/ui/navigation/navigation_bar')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local TrustInfoBar = setmetatable({}, {__index = CollectionView })
TrustInfoBar.__index = TrustInfoBar
TrustInfoBar.__type = "TrustInfoBar"

function TrustInfoBar.new(frame)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local itemSize
        if indexPath.row == 1 then
            itemSize = 111
        else
            itemSize = frame.width - 111 - 15 - 4
        end
        local cell = InfoBarCollectionViewCell.new(Frame.new(0, 0, itemSize, frame.height))
        cell:setTitle(item:getText())
        cell:setItemSize(itemSize)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, HorizontalFlowLayout.new(4, Padding.new(0, 0, 0, 0))), TrustInfoBar)

    self:setSize(0, frame.height)
    self:setUserInteractionEnabled(false)
    self:setScrollEnabled(false)

    self:getDataSource():addItems(L{
        IndexedItem.new(TextItem.new("", TextStyle.Default.ButtonSmall), IndexPath.new(1, 1)),
        IndexedItem.new(TextItem.new("", TextStyle.Default.ButtonSmall), IndexPath.new(1, 2)),
    })

    return self
end

function TrustInfoBar:setTitle(title)
    local titleItem = TextItem.new(title or "", TextStyle.Default.ButtonSmall)
    self:getDataSource():updateItem(titleItem, IndexPath.new(1, 1))
end

function TrustInfoBar:setDescription(description)
    local descriptionItem = TextItem.new(description or "", TextStyle.Default.ButtonSmall)
    self:getDataSource():updateItem(descriptionItem, IndexPath.new(1, 2))
end

return TrustInfoBar