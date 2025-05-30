local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ItemDescription = require('resources/resources').ItemDescription
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local ItemDescriptionView = setmetatable({}, {__index = FFXIWindow})
ItemDescriptionView.__index = ItemDescriptionView


function ItemDescriptionView.new(itemId)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        if item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(96)
            return cell
        end
    end)
    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0), nil, false, Frame.new(0, 0, 344, 96)), ItemDescriptionView)
    self:setItemId(itemId)
    return self
end

function ItemDescriptionView:setItemId(itemId)
    if self.itemId == itemId then
        return
    end
    self.itemId = itemId

    local matches = ItemDescription:where({ id = itemId }, L{ 'en' })
    if matches:length() > 0 then
        self:getDataSource():updateItems(L{ IndexedItem.new(TextItem.new(matches[1].en, TextStyle.Default.TextSmall), IndexPath.new(1, 1)) })
    else
        self:getDataSource():updateItems(L{ IndexedItem.new(TextItem.new('', TextStyle.Default.TextSmall), IndexPath.new(1, 1)) })
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

return ItemDescriptionView