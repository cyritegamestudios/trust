local BagMenuItem = require('ui/views/inventory/BagMenuItem')
local Inventory = require('cylibs/inventory/inventory')
local MenuItem = require('cylibs/ui/menu/menu_item')

local InventoryMenuItem = setmetatable({}, {__index = MenuItem })
InventoryMenuItem.__index = InventoryMenuItem

function InventoryMenuItem.new()
    local self = setmetatable(MenuItem.new(L{}, {}, nil, "Inventory", "View contents of inventory, storage and wardrobes."), InventoryMenuItem)

    local inventory = Inventory.new()

    local bags = inventory:getAllBags()
    for bag in bags:it() do
        self:setChildMenuItem(bag:getName(), BagMenuItem.new(bag))
    end

    return self
end

return InventoryMenuItem