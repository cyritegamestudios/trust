local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local GridLayout = require('cylibs/ui/collection_view/layouts/grid_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local EquipSetView = setmetatable({}, {__index = FFXIWindow })
EquipSetView.__index = EquipSetView


function EquipSetView.new(equipSet)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == ImageItem.__type then
            local cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(32)
            return cell
        end
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, GridLayout.new(0, Padding.equal(0), 0, 128, 32, 32), nil, false, Frame.new(0, 0, 176, 144)), EquipSetView)

    self.equipmentSlotBackgroundView = self:getEquipmentSlotBackgroundView()
    self:getContentView():addSubview(self.equipmentSlotBackgroundView)

    self:reloadEquipSet(equipSet)

    return self
end

function EquipSetView:reloadEquipSet(equipSet)
    self:getDataSource():removeAllItems()

    local itemsToAdd = L{}

    --[[for slot = 1, 16 do
        local imageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32)
        imageItem:setAlpha(128)
        itemsToAdd:append(IndexedItem.new(imageItem, IndexPath.new(1, slot)))
    end]]

    self:getDataSource():addItems(itemsToAdd)
end

function EquipSetView:getEquipmentSlotBackgroundView()
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == ImageItem.__type then
            local cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(32)
            return cell
        end
    end)

    local itemsToAdd = L{}

    for slot = 1, 16 do
        local imageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32)
        imageItem:setAlpha(128)
        itemsToAdd:append(IndexedItem.new(imageItem, IndexPath.new(1, slot)))
    end

    local slotBackgroundView = CollectionView.new(dataSource, GridLayout.new(0, Padding.equal(0), 0, 128, 32, 32))
    slotBackgroundView:setSize(128, 128)

    slotBackgroundView:getDataSource():addItems(itemsToAdd)

    return slotBackgroundView
end

function EquipSetView:layoutIfNeeded()
    local needsLayout = CollectionView.layoutIfNeeded(self)
    if not needsLayout then
        return false
    end

    self.equipmentSlotBackgroundView:setPosition((self:getSize().width - self.equipmentSlotBackgroundView:getSize().width) / 2, 8)
end

return EquipSetView