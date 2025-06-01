local EquipSet = require('cylibs/inventory/equipment/equip_set')
local inventory_util = require('cylibs/util/inventory_util')

local Equipment = {}
Equipment.__index = Equipment
Equipment.__type = "Equipment"

function Equipment.new()
    local self = setmetatable({}, Equipment)
    return self
end

function Equipment:getEquipSet()
    local equipSet = EquipSet.new(
        inventory_util.get_equipment(EquipSet.Slot.Main),
        inventory_util.get_equipment(EquipSet.Slot.Sub),
        inventory_util.get_equipment(EquipSet.Slot.Range),
        inventory_util.get_equipment(EquipSet.Slot.Ammo),
        inventory_util.get_equipment(EquipSet.Slot.Head),
        inventory_util.get_equipment(EquipSet.Slot.Neck),
        inventory_util.get_equipment(EquipSet.Slot.Ear1),
        inventory_util.get_equipment(EquipSet.Slot.Ear2),
        inventory_util.get_equipment(EquipSet.Slot.Body),
        inventory_util.get_equipment(EquipSet.Slot.Hands),
        inventory_util.get_equipment(EquipSet.Slot.Ring1),
        inventory_util.get_equipment(EquipSet.Slot.Ring2),
        inventory_util.get_equipment(EquipSet.Slot.Back),
        inventory_util.get_equipment(EquipSet.Slot.Waist),
        inventory_util.get_equipment(EquipSet.Slot.Legs),
        inventory_util.get_equipment(EquipSet.Slot.Feet)
    )
    return equipSet
end

return Equipment
