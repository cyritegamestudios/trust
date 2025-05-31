local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local EquipSetView = require('ui/views/inventory/equipment/EquipSetView')
local InventoryMenuItem = require('ui/views/inventory/InventoryMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')


local EquipSetMenuItem = setmetatable({}, {__index = MenuItem })
EquipSetMenuItem.__index = EquipSetMenuItem

function EquipSetMenuItem.new(equipSet)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {
        Confirm = MenuItem.action(function()
            equipSet:save()
            print('saved set')
        end, "Confirm", "Save the equip set.")
    }, function(_, _, _)
        local equipSetView = EquipSetView.new(equipSet or player.party:get_player():get_current_equip_set())
        return equipSetView
    end, "Equip Set", string.format("View equipment in this set.")), EquipSetMenuItem)

    self.equipSet = equipSet

    return self
end

return EquipSetMenuItem