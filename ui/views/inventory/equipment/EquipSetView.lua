local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local GridLayout = require('cylibs/ui/collection_view/layouts/grid_layout')
local icon_extractor = require('cylibs/util/images/icon_extractor')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local View = require('cylibs/ui/views/view')

local EquipSetView = setmetatable({}, {__index = View })
EquipSetView.__index = EquipSetView


function EquipSetView.new(equipSet)
    local viewSize = Frame.new(0, 0, 176, 144)

    local self = setmetatable(View.new(viewSize), EquipSetView)

    local backgroundView = FFXIBackgroundView.new(viewSize, true, CollectionView.defaultStyle())
    self:setBackgroundImageView(backgroundView)

    self.containerView = View.new(Frame.new(0, 0, 128, 128))
    self:addSubview(self.containerView)

    self.containerView:addSubview(self:createEquipmentSlotView(ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32, 128)))

    self.equipmentSlotView = self:createEquipmentSlotView(ImageItem.new('', 32, 32))
    self.equipmentSlotView:setAllowsCursorSelection(true)

    self.containerView:addSubview(self.equipmentSlotView)

    self:reloadEquipSet(equipSet)

    return self
end

function EquipSetView:reloadEquipSet(equipSet)
    self.equipmentSlotView:getDataSource():removeAllItems()

    local itemToUpdate = L{}

    for slot, itemId in equipSet:it() do
        local iconPath = string.format('%s/%s.bmp', windower.addon_path..'assets/equipment', itemId)

        if not windower.file_exists(iconPath) then
            icon_extractor.item_by_id(itemId, iconPath)
        end

        local imageItem = ImageItem.new(iconPath, 32, 32)

        itemToUpdate:append(IndexedItem.new(imageItem, IndexPath.new(1, slot)))
    end

    self.equipmentSlotView:getDataSource():updateItems(itemToUpdate)
end

function EquipSetView:createEquipmentSlotView(defaultImageItem)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == ImageItem.__type then
            local cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(32)
            return cell
        end
    end)

    local itemsToAdd = L{}

    for slot = 1, 16 do
        itemsToAdd:append(IndexedItem.new(defaultImageItem, IndexPath.new(1, slot)))
    end

    local slotBackgroundView = CollectionView.new(dataSource, GridLayout.new(0, Padding.equal(0), 0, 128, 32, 32))
    slotBackgroundView:setSize(128, 128)

    slotBackgroundView:getDataSource():addItems(itemsToAdd)

    slotBackgroundView:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return slotBackgroundView
end

function EquipSetView:layoutIfNeeded()
    local needsLayout = View.layoutIfNeeded(self)
    if not needsLayout then
        return false
    end

    if self.containerView then
        self.containerView:setPosition((self:getSize().width - self.containerView:getSize().width) / 2, 8)
    end
end

function EquipSetView:requestFocus()
    View.requestFocus(self)

    self.equipmentSlotView:requestFocus()
end

function EquipSetView:resignFocus()
    View.resignFocus(self)

    self.equipmentSlotView:resignFocus()
end

return EquipSetView