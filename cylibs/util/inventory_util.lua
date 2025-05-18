---------------------------
-- Utility functions for inventory, wardrobes, satchels, cases and storage.
-- @class module
-- @name InventoryUtil

local inventory_util = {}

local food_cache = T(require('cylibs/res/food'))
local Item = require('resources/resources').Item

-------
-- Returns abridged metadata for food items.
-- @treturn table Metadata for food items (see cylibs/res/food.lua)
function inventory_util.all_food()
    return food_cache
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
        local item = Item:get({ en = item_id })
        if item then
            item_id = item.id
        end
    end
    local item_count = 0
    for bag in L{ 'inventory', 'temporary' }:it() do
        local items = L(windower.ffxi.get_items(bag))
        for item in items:it() do
            if item.id == item_id then
                item_count = item_count + item.count
            end
        end
        if item_count > 0 then
            return item_count
        end
    end
    return item_count
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

function inventory_util.get_equipment_ids()
    local item = windower.ffxi.get_items('equipment')
    local slots = {'main','sub','range','head','neck','body','hands','legs','feet','back'}
    local equipment_ids = L{}
    for _,slot in ipairs(slots) do
        equipment_ids:append(windower.ffxi.get_items(item[slot..'_bag'],item[slot]).id)
    end
    return equipment_ids
end

return inventory_util