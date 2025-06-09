local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local EquipmentPickerView = require('ui/views/inventory/equipment/EquipmentPickerView')
local EquipSet = require('cylibs/inventory/equipment/equip_set')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')
local GridLayout = require('cylibs/ui/collection_view/layouts/grid_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local Padding = require('cylibs/ui/style/padding')

local SlotItem = setmetatable({}, {__index = ImageItem})
SlotItem.__index = SlotItem
SlotItem.__type = "SlotItem"
SlotItem.__class = "SlotItem"

---
-- Creates a new SlotItem instance.
--
-- @tparam number slot The slot number (see res/slots.lua).
-- @tparam number itemId The item id (see res/items.lua).
-- @treturn SlotItem The newly created SlotItem instance.
--
function SlotItem.new(slot, itemId)
    local self = setmetatable(AssetManager.imageItemForItem(itemId), SlotItem)
    self.slot = slot
    return self
end

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local EquipSetView = setmetatable({}, {__index = FFXIWindow})
EquipSetView.__index = EquipSetView


function EquipSetView.new(equipSet)
    local itemSize = 32

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == SlotItem.__type then
            local slotBackgroundView = ImageCollectionViewCell.new(ImageItem.new(windower.addon_path..'assets/backgrounds/item_slot_background.png', 32, 32, 128))

            local cell = ImageCollectionViewCell.new(item)
            cell:setItemSize(itemSize)
            cell:addSubview(slotBackgroundView)
            return cell
        end
    end)

    local viewSize = Frame.new(0, 0, 160, 192)

    local self = setmetatable(FFXIWindow.new(dataSource, GridLayout.new(2, Padding.new(14, 12, 0, 0), 0, 136, itemSize, itemSize), nil, false, viewSize, FFXIClassicStyle.slot()), EquipSetView)

    self.resignFocusKeys = L{ 1 }
    self.scrollNextKey = 205
    self.scrollPreviousKey = 203

    self:setEquipSet(equipSet)

    self.equipmentPickerView = EquipmentPickerView.new(L{ 0 })
    self:addSubview(self.equipmentPickerView)

    self:getDisposeBag():add(self.equipmentPickerView:onEquipmentPicked():addAction(function(equipmentPickerView, itemId, slot)
        equipSet[slot] = itemId
        self:setEquipSet(equipSet)
        equipmentPickerView:resignFocus()
    end), self.equipmentPickerView:onEquipmentPicked())

    self:getDisposeBag():add(self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        self.equipmentPickerView:setSlots(L{ item.slot })
    end), self:getDelegate():didMoveCursorToItemAtIndexPath())

    return self
end

function EquipSetView:getSlotOrder()
    return L{ 0, 1, 2, 3, 4, 9, 11, 12, 5, 6, 13, 14, 15, 10, 7, 8 }
end

function EquipSetView:setEquipSet(equipSet)
    self.equipSet = equipSet

    local itemToUpdate = L{}

    for i, slot in pairs(self:getSlotOrder()) do
        if type(i) == 'number' then
            itemToUpdate:append(IndexedItem.new(SlotItem.new(slot, self.equipSet[slot]), IndexPath.new(1, i)))
        end
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
    return needsLayout
end

function EquipSetView:onSelectMenuItemAtIndexPath(textItem, _)
    if L{ 'Clear' }:contains(textItem:getText()) then
        local indexPath = self:getDelegate():getCursorIndexPath()

        local slot = self:getSlotOrder()[indexPath.row]

        self.equipSet[slot] = 65535

        self:setEquipSet(self.equipSet)
    end
end

function EquipSetView:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or FFXIWindow.onKeyboardEvent(self, key, pressed, flags, blocked)
    if pressed then
        local key = Keyboard.input():getKey(key)
        if key then
            if key == 'Enter' then
                self.equipmentPickerView:requestFocus()
                return true
            end
        end
    end
    return blocked
end

function EquipSetView:onMouseEvent(type, x, y, delta)
    if self.equipmentPickerView:onMouseEvent(type, x, y, delta) then
        return true
    end
    return FFXIWindow.onMouseEvent(self, type, x, y, delta)
end

function EquipSetView:hitTest(x, y)
    return FFXIWindow.hitTest(self, x, y) or self.equipmentPickerView:hitTest(x, y)
end

return EquipSetView