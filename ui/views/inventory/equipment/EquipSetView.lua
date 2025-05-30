local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local EquipmentPickerView = require('ui/views/inventory/equipment/EquipmentPickerView')
local EquipSet = require('cylibs/inventory/equipment/equip_set')
local Event = require('cylibs/events/Luvent')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')
local GridLayout = require('cylibs/ui/collection_view/layouts/grid_layout')
local icon_extractor = require('cylibs/util/images/icon_extractor')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local Padding = require('cylibs/ui/style/padding')
local View = require('cylibs/ui/views/view')



-- EquipSetView

--[[local EquipSetView = setmetatable({}, {__index = View })
EquipSetView.__index = EquipSetView


function EquipSetView.new(equipSet)
    local viewSize = Frame.new(0, 0, 176, 150)

    local self = setmetatable(View.new(viewSize), EquipSetView)

    local backgroundView = FFXIBackgroundView.new(viewSize, true, CollectionView.defaultStyle())
    self:setBackgroundImageView(backgroundView)

    self.equipmentPickerView = EquipmentPickerView.new(L{ EquipSet.Slot.Head })
    self:addSubview(self.equipmentPickerView)

    self.containerView = View.new(Frame.new(0, 0, 136, 128))
    self:addSubview(self.containerView)

    self.containerView:addSubview(self:createEquipmentSlotBackgroundView(ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32, 128)))

    self.equipmentSlotView = EquipmentSlotGrid.new(equipSet)
    self.equipmentSlotView:setAllowsCursorSelection(true)

    self.equipmentSlotView:onSlotSelected():addAction(function(_, _)
        self.equipmentPickerView:requestFocus()
    end)
    self.equipmentSlotView:onSlotHighlighted():addAction(function(_, slot)
        self.equipmentPickerView:setSlots(S{ slot })
    end)

    self.containerView:addSubview(self.equipmentSlotView)

    return self
end

function EquipSetView:createEquipmentSlotBackgroundView(defaultImageItem)
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

    local slotBackgroundView = CollectionView.new(dataSource, GridLayout.new(2, Padding.equal(0), 0, 136, 32, 32))
    slotBackgroundView:setSize(136, 128)

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

        self.equipmentPickerView:setPosition(self:getSize().width + 4, 0)
        self.equipmentPickerView:layoutIfNeeded()
    end
end

function EquipSetView:requestFocus()
    View.requestFocus(self)

    self.equipmentSlotView:requestFocus()
end

return EquipSetView]]

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local EquipSetView = setmetatable({}, {__index = FFXIWindow})
EquipSetView.__index = EquipSetView

function EquipSetView:onSlotSelected()
    return self.slotSelected
end

function EquipSetView:onSlotHighlighted()
    return self.slotHighlighted
end

function EquipSetView.new(equipSet)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == ImageItem.__type then
            local slotBackgroundView = ImageCollectionViewCell.new(ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32, 128))

            local cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(32)
            cell:addSubview(slotBackgroundView)
            return cell
        end
    end)

    local viewSize = Frame.new(0, 0, 160, 160)

    local self = setmetatable(FFXIWindow.new(dataSource, GridLayout.new(2, Padding.new(14, 12, 0, 0), 0, 136, 32, 32), nil, false, viewSize, FFXIClassicStyle.slot()), EquipSetView)

    self:setEquipSet(equipSet)

    self.equipmentPickerView = EquipmentPickerView.new(L{ EquipSet.Slot.Head })
    self:addSubview(self.equipmentPickerView)

    self.slotSelected = Event.newEvent()
    self.slotHighlighted = Event.newEvent()

    self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
        local slotIndex = indexPath.row
        self:onSlotHighlighted():trigger(self, EquipSet.Slot.AllSlots[slotIndex])
        self.equipmentPickerView:setSlots(S{ EquipSet.Slot.AllSlots[slotIndex] })
    end)

    return self
end

function EquipSetView:destroy()
    FFXIWindow.destroy(self)

    self.slotSelected:removeAllActions()
    self.slotHighlighted:removeAllActions()
end

function EquipSetView:setEquipSet(equipSet)
    if self.equipSet == equipSet then
        return
    end
    self.equipSet = equipSet

    local itemToUpdate = L{}

    for slot, itemId in equipSet:it() do
        local iconPath = string.format('%s/%s.bmp', windower.addon_path..'assets/equipment', itemId)

        if not windower.file_exists(iconPath) then
            icon_extractor.item_by_id(itemId, iconPath)
        end

        local imageItem = ImageItem.new(iconPath, 32, 32)

        itemToUpdate:append(IndexedItem.new(imageItem, IndexPath.new(1, slot)))
    end

    self:getDataSource():updateItems(itemToUpdate)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
end

function EquipSetView:layoutIfNeeded()
    local needsLayout = FFXIWindow.layoutIfNeeded(self)
    if not needsLayout then
        return false
    end

    if self.equipmentPickerView then
        self.equipmentPickerView:setPosition(self:getSize().width + 4, 0)
        self.equipmentPickerView:layoutIfNeeded()
    end
end

function EquipSetView:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or CollectionView.onKeyboardEvent(self, key, pressed, flags, blocked)
    if blocked then
        return true
    end
    if pressed then
        local key = Keyboard.input():getKey(key)
        if key then
            if key == 'Enter' then
                local selectedSlotIndex = self:getDelegate():getCursorIndexPath().row
                self.equipmentPickerView:requestFocus()
                self:onSlotSelected():trigger(self, EquipSet.Slot.AllSlots[selectedSlotIndex])
                return true
            end
        end
    end
    return false
end

return EquipSetView