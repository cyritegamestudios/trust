local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Item = require('resources/resources').Item
local ItemDescription = require('resources/resources').ItemDescription
local Padding = require('cylibs/ui/style/padding')
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
            cell:setItemSize(16)
            cell:setUserInteractionEnabled(true)
            return cell
        elseif item.__type == ImageTextItem.__type then
            local slotBackgroundView = ImageCollectionViewCell.new(ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32, 128))
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setItemSize(32)
            cell.imageView:addSubview(slotBackgroundView)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, Padding.new(6, 6, 0, 0)), nil, false, Frame.new(0, 0, 344, 96)), ItemDescriptionView)

    self:setScrollEnabled(true)
    self:setUserInteractionEnabled(true)
    self:setAllowsCursorSelection(true)

    self:setItemId(itemId)

    return self
end

function ItemDescriptionView:setItemId(itemId)
    if self.itemId == itemId then
        return
    end
    self.itemId = itemId

    local itemDescriptions = ItemDescription:where({ id = itemId }, L{ 'en' })
    if itemDescriptions:length() > 0 then
        local item = Item:where({ id = itemId }, L{ 'en '})[1]
        --local itemDescription = string.format("%s\n%s", item.en, itemDescriptions[1].en)

        local titleItem = ImageTextItem.new(AssetManager.imageItemForItem(itemId), TextItem.new(item.en, TextStyle.Default.TextSmall:bolded(true)), 8, { x = 0, y = 4 })

        local descriptionItems = L(string.split(itemDescriptions[1].en, '\n')):map(function(row)
            local textItem = TextItem.new(row, TextStyle.Default.TextSmall:bolded(true))
            textItem:setOffset(40, 0)
            return textItem
        end)

        self:getDataSource():updateItems(IndexedItem.fromItems(L{ titleItem } + descriptionItems, 1))

        --self:getDataSource():updateItems(L{ IndexedItem.new( ImageTextItem.new(AssetManager.imageItemForItem(itemId), TextItem.new(itemDescription, TextStyle.Default.TextSmall:bolded(true)), 8, { x = 0, y = 4 }), IndexPath.new(1, 1)) })
    else
        self:getDataSource():updateItems(L{ IndexedItem.new(TextItem.new('', TextStyle.Default.TextSmall), IndexPath.new(1, 1)) })
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

return ItemDescriptionView