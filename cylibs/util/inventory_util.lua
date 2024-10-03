---------------------------
-- Utility functions for inventory, wardrobes, satchels, cases and storage.
-- @class module
-- @name InventoryUtil

local inventory_util = {}
local item_cache = T(require('cylibs/res/items'))

function inventory_util.all_items()
    return item_cache
end

-------
-- Returns the inventory index for an item.
-- @tparam number item_id Item id (see res/items.lua)
-- @treturn number Index of the item in the inventory, or nil if it doesn't exist
function inventory_util.get_inventory_index(item_id)
    local items = L(windower.ffxi.get_items('inventory'))
    local item_index = 1
    for item in items:it() do
        if item.id == item_id then
            return item_index
        end
        item_index = item_index + 1
    end
    return nil
end

-------
-- Returns the number of the given item in the player's inventory.
-- @tparam number item_id Item id (see res/items.lua)
-- @treturn number Number of items
function inventory_util.get_item_count(item_id)
    if type(item_id) == 'string' then
        local item = inventory_util.all_items():with('en', item_id)
        if item then
            item_id = item.id
        end
    end
    local items = L(windower.ffxi.get_items('inventory'))
    for item in items:it() do
        if item.id == item_id then
            return item.count
        end
    end
    return 0
end

-------
-- Returns the item id of the main weapon equipped.
-- @treturn number Item id of the main weapon equipped (see res/items.lua)
function inventory_util.get_main_weapon_id()
    local equipment = windower.ffxi.get_items('equipment')

    local main_weapon_id = windower.ffxi.get_items(equipment.main_bag, equipment.main).id
    if main_weapon_id == 65535 then
        return nil
    end
    return main_weapon_id
end

-------
-- Returns the item id of the ranged weapon equipped.
-- @treturn number Item id of the ranged weapon equipped (see res/items.lua)
function inventory_util.get_ranged_weapon_id()
    local equipment = windower.ffxi.get_items('equipment')

    local ranged_weapon_id = windower.ffxi.get_items(equipment.range_bag, equipment.range).id
    if ranged_weapon_id == 65535 then
        return nil
    end
    return ranged_weapon_id
end

return inventory_util