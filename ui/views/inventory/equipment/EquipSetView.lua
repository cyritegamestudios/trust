local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local EquipmentPickerView = require('ui/views/inventory/equipment/EquipmentPickerView')
local EquipSet = require('cylibs/inventory/equipment/equip_set')
local Event = require('cylibs/events/Luvent')
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

    local viewSize = Frame.new(0, 0, 160, 192)

    local self = setmetatable(FFXIWindow.new(dataSource, GridLayout.new(2, Padding.new(14, 12, 0, 0), 0, 136, 32, 32), nil, false, viewSize, FFXIClassicStyle.slot()), EquipSetView)

    self:setEquipSet(equipSet)

    self.equipmentPickerView = EquipmentPickerView.new(L{ EquipSet.Slot.Head })
    self:addSubview(self.equipmentPickerView)

    self.resignFocusKeys = L{ 1 }
    self.scrollNextKey = 205
    self.scrollPreviousKey = 203
    self.slotSelected = Event.newEvent()
    self.slotHighlighted = Event.newEvent()

    self:getDisposeBag():add(self.equipmentPickerView:onEquipmentPicked():addAction(function(equipmentPickerView, itemId, slot)
        equipSet[slot] = itemId

        self:setEquipSet(equipSet)

        equipmentPickerView:resignFocus()
    end), self.equipmentPickerView:onEquipmentPicked())

    self:getDisposeBag():add(self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
        local slotIndex = indexPath.row
        self:onSlotHighlighted():trigger(self, EquipSet.Slot.AllSlots[slotIndex])
        self.equipmentPickerView:setSlots(S{ EquipSet.Slot.AllSlots[slotIndex] })
    end), self:getDelegate():didMoveCursorToItemAtIndexPath())

    return self
end

function EquipSetView:destroy()
    FFXIWindow.destroy(self)

    self.slotSelected:removeAllActions()
    self.slotHighlighted:removeAllActions()
end

function EquipSetView:setEquipSet(equipSet)
    --if self.equipSet == equipSet then
    --    return
    --end
    self.equipSet = equipSet

    local itemToUpdate = L{}

    for slot, itemId in equipSet:it() do
        itemToUpdate:append(IndexedItem.new(AssetManager.imageItemForItem(itemId), IndexPath.new(1, slot)))
    end

    self:getDataSource():updateItems(itemToUpdate)

    self:setNeedsLayout()
    self:layoutIfNeeded()

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
    local blocked = blocked or FFXIWindow.onKeyboardEvent(self, key, pressed, flags, blocked)
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
    return blocked
end

return EquipSetView