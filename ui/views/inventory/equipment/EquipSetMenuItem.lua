local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local EquipSetView = require('ui/views/inventory/equipment/EquipSetView')
local MenuItem = require('cylibs/ui/menu/menu_item')


local EquipSetMenuItem = setmetatable({}, {__index = MenuItem })
EquipSetMenuItem.__index = EquipSetMenuItem

function EquipSetMenuItem.new(equipSet)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_, infoView, _)
        local equipSetView = EquipSetView.new(equipSet)
        return equipSetView
    end, "Equip Set", string.format("View equipment in this set.")), EquipSetMenuItem)

    self.equipSet = equipSet

    return self
end

return EquipSetMenuItem