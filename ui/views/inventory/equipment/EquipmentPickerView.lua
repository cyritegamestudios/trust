local EquipSet = require('cylibs/inventory/equipment/equip_set')
local Event = require('cylibs/events/Luvent')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Item = require('resources/resources').Item
local ItemDescriptionView = require('ui/views/inventory/ItemDescriptionView')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local EquipmentPickerView = setmetatable({}, {__index = FFXIPickerView })
EquipmentPickerView.__index = EquipmentPickerView

function EquipmentPickerView:onEquipmentPicked()
    return self.equipmentPicked
end

function EquipmentPickerView.new(slots)
    local self = setmetatable(FFXIPickerView.withConfig(MultiPickerConfigItem.new("Items", L{}, L{})), EquipmentPickerView)

    self.itemDescriptionView = ItemDescriptionView.new()
    self:addSubview(self.itemDescriptionView)

    self:setSlots(slots)

    self:getDisposeBag():add(self:on_select_items():addAction(function(_, selectedItems, _)
        self.itemDescriptionView:setItemId(selectedItems[1].id)
        self:onEquipmentPicked():trigger(self, selectedItems[1].id, L(self.slots)[1])
    end), self:on_select_items())

    self:getDisposeBag():add(self:getDelegate():didHighlightItemAtIndexPath():addAction(function(indexPath)

    end), self:getDelegate():didHighlightItemAtIndexPath())

    self.equipmentPicked = Event.newEvent()

    return self
end

function EquipmentPickerView:destroy()
    FFXIPickerView.destroy(self)

    self.equipmentPicked:removeAllActions()
end

function EquipmentPickerView:setSlots(slots)
    if self.slots == slots then
        return
    end
    self.slots = slots

    local allItems = windower.trust.get_inventory():getAllBags():map(function(bag)
        local items = bag:getItems():filter(function(item)
            local matches = Item:where({ id = item.id }, L{ 'en', 'slots' })
            if matches:length() > 0 and matches[1].slots then
                local match = matches[1]
                return item.id ~= 0 and S(slots):intersection(S(EquipSet.getSlotsForMask(match.slots))):length() > 0
            end
            return false
        end)
        return items
    end):flatten(false)

    local configItem = MultiPickerConfigItem.new("Items", L{}, allItems, function(item)
        local matches = Item:where({ id = item.id }, L{ 'en' })
        if matches:length() > 0 then
            return matches[1].en
        end
        return "Unknown"
    end)
    self:setConfigItems(L{ configItem })

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function EquipmentPickerView:layoutIfNeeded()
    local needsLayout = FFXIPickerView.layoutIfNeeded(self)

    self.itemDescriptionView:setPosition(-164, self:getSize().height + 6)

    return needsLayout
end

return EquipmentPickerView