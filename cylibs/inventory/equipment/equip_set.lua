local EquipSets = require('settings/settings').EquipSet

local EquipSet = {}
EquipSet.__type = "EquipSet"
EquipSet.__index = EquipSet

-- Slot ordering and name mappings
local slot_order = {
    "main", "sub", "range", "ammo",
    "head", "body", "hands", "legs", "feet",
    "neck", "waist", "left_ear", "right_ear",
    "left_ring", "right_ring", "back"
}

EquipSet.Slot = {}
EquipSet.Slot.AllSlots = L(slot_order)
EquipSet.Slot.id_to_name = {}
EquipSet.Slot.name_to_id = {}

for id, name in ipairs(slot_order) do
    local slot_id = id - 1
    EquipSet.Slot.id_to_name[slot_id] = name
    EquipSet.Slot.name_to_id[name] = slot_id
end

-- Constructor: accepts values in slot ID order (0–15)
function EquipSet.new(...)
    local self = setmetatable({}, EquipSet)
    local args = { ... }
    for i = 1, #args do
        rawset(self, i - 1, args[i])
    end
    return self
end

function EquipSet.named(equip_set_name)
    local row = EquipSets:get({
        name = equip_set_name,
        user_id = windower.ffxi.get_player().id,
    })

    if not row then
        return nil
    end

    local slot_values = {}
    for _, slot in ipairs(EquipSet.Slot.AllSlots) do
        table.insert(slot_values, row[slot])
    end

    local equipSet = EquipSet.new(table.unpack(slot_values))

    return equipSet
end

-- Access by string or integer
function EquipSet:__index(k)
    if type(k) == "string" then
        local id = EquipSet.Slot.name_to_id[k]
        if id ~= nil then return rawget(self, id) end

        -- For _ext_data
        if k:match("_ext_data$") then
            local slot_name = k:match("^(.*)_ext_data$")
            local slot_id = EquipSet.Slot.name_to_id[slot_name]
            if slot_id ~= nil then
                return rawget(self, slot_id .. "_ext")
            end
        end
    elseif type(k) == "number" then
        return rawget(self, k)
    end
    return rawget(EquipSet, k)
end

-- Assignment by string or integer
function EquipSet:__newindex(k, v)
    if type(k) == "string" then
        local id = EquipSet.Slot.name_to_id[k]
        if id ~= nil then
            rawset(self, id, v)
            return
        end

        if k:match("_ext_data$") then
            local slot_name = k:match("^(.*)_ext_data$")
            local slot_id = EquipSet.Slot.name_to_id[slot_name]
            if slot_id ~= nil then
                rawset(self, slot_id .. "_ext", v)
                return
            end
        end
    elseif type(k) == "number" then
        rawset(self, k, v)
        return
    end
    rawset(self, k, v)
end

-- Iterator over slots in visual order
function EquipSet:it()
    local i = 0
    return function()
        i = i + 1
        local slot_name = EquipSet.Slot.AllSlots[i]
        if slot_name then
            local slot_id = EquipSet.Slot.name_to_id[slot_name]
            return slot_id, self[slot_id]
        end
    end
end

-- Copy method
function EquipSet:copy()
    local copy = EquipSet.new()
    for slot_id, _ in pairs(EquipSet.Slot.id_to_name) do
        copy[slot_id] = self[slot_id]
        copy[slot_id .. "_ext"] = self[slot_id .. "_ext"]
    end
    return copy
end

-- Save to database
function EquipSet:save(equip_set_name)
    local CanEquipSetCondition = require('cylibs/conditions/can_equip_set')

    local equipSet = EquipSets:get({ name = equip_set_name, user_id = windower.ffxi.get_player().id }) or EquipSets({
        name = equip_set_name,
        user_id = windower.ffxi.get_player().id
    })
    -- Copy all slot values and ext_data from this EquipSet
    for slot_id, slot_name in pairs(EquipSet.Slot.id_to_name) do
        equipSet[slot_name] = self[slot_id]
        equipSet[slot_name .. "_ext_data"] = self[slot_id .. "_ext"]
    end

    equipSet:save()
    equipSet:save()

    if not Condition.check_conditions(L{ CanEquipSetCondition.new(equip_set_name) }, windower.ffxi.get_player().index) then
        addon_system_error(string.format("%s is not a valid set.", equip_set_name))
    end
end

-- Optional: tostring
function EquipSet:__tostring()
    local parts = {}
    for slot_id, slot_name in pairs(EquipSet.Slot.id_to_name) do
        local itemId = self[slot_id]
        if itemId ~= nil then
            table.insert(parts, string.format("[%s] = %d", slot_name, itemId))
        end
    end
    return string.format("EquipSet {\n  %s\n}", table.concat(parts, "\n  "))
end

return EquipSet


--[[local EquipSet = {}
EquipSet.__type = "EquipSet"
EquipSet.__index = EquipSet

-- Define slot metadata: key = name, value = bit position
local slot_definitions = {
    { name = "main",        bit = 0 },
    { name = "sub",         bit = 1 },
    { name = "range",       bit = 2 },
    { name = "ammo",        bit = 3 },
    { name = "head",        bit = 4 },
    { name = "body",        bit = 5 },
    { name = "hands",       bit = 6 },
    { name = "legs",        bit = 7 },
    { name = "feet",        bit = 8 },
    { name = "neck",        bit = 9 },
    { name = "waist",       bit = 10 },
    { name = "left_ear",    bit = 11 },
    { name = "right_ear",   bit = 12 },
    { name = "left_ring",   bit = 13 },
    { name = "right_ring",  bit = 14 },
    { name = "back",        bit = 15 },
}

-- Initialize Slot constants and maps
EquipSet.Slot = {}
EquipSet.Slot.AllSlots = L{
    "main",         -- 1
    "sub",          -- 2
    "range",        -- 3
    "ammo",         -- 4
    "head",         -- 5
    "neck",         -- 6
    "left_ear",     -- 7
    "right_ear",    -- 8
    "body",         -- 9
    "hands",        -- 10
    "left_ring",    -- 11
    "right_ring",   -- 12
    "back",         -- 13
    "waist",        -- 14
    "legs",         -- 15
    "feet",         -- 16
}

local slot_bit_map = {}

for _, slot in ipairs(slot_definitions) do
    local mask = bit.lshift(1, slot.bit)
    EquipSet.Slot[slot.name:gsub("^%l", string.upper)] = slot.name -- e.g. Slot.Main = "main"
    slot_bit_map[mask] = slot.name
end

-- Constructor
function EquipSet.new(...)
    local self = setmetatable({}, EquipSet)
    local args = {...}
    for i, slot in ipairs(EquipSet.Slot.AllSlots) do
        self[slot] = args[i]
    end
    return self
end

function EquipSet.named(equip_set_name)
    local row = EquipSets:get({
        name = equip_set_name,
        user_id = windower.ffxi.get_player().id,
    })

    if not row then
        return nil
    end

    local slot_values = {}
    for _, slot in ipairs(EquipSet.Slot.AllSlots) do
        table.insert(slot_values, row[slot])
    end

    local equipSet = EquipSet.new(table.unpack(slot_values))

    return equipSet
end

-- Bitmask-based slot lookup
EquipSet.getSlotsForMask = function(mask)
    local slots = {}
    for bitmask, slot_name in pairs(slot_bit_map) do
        if bit.band(tonumber(mask), bitmask) ~= 0 then
            table.insert(slots, slot_name)
        end
    end
    return slots
end

EquipSet.getSlotNameForSlot = function(slot_id)
    for _, slot in ipairs(slot_definitions) do
        if slot.bit == slot_id then
            return slot.name
        end
    end
    return nil
end

-- Allow indexed access using bitmask numbers
EquipSet.__index = function(t, k)
    if type(k) == 'number' and slot_bit_map[bit.lshift(1, k)] then
        return rawget(t, slot_bit_map[bit.lshift(1, k)])
    end
    return rawget(EquipSet, k) or rawget(t, k)
end

EquipSet.__newindex = function(t, k, v)
    if type(k) == 'number' and slot_bit_map[bit.lshift(1, k)] then
        rawset(t, slot_bit_map[bit.lshift(1, k)], v)
    else
        rawset(t, k, v)
    end
end


-- Delta between the given equip set
function EquipSet:delta(equipSet)
    local result = {}
    for slot, _ in pairs(res.slots) do
        if equipSet[slot] ~= 65535 and self[slot] ~= equipSet[slot] then
            result[slot] = equipSet[slot]
        end
    end
    return result
end

-- Iterator
-- Note that this does NOT go in the order in res.slots or the order 0x051 expects. It's meant to go in
-- the order in which gear slots appear in the equip set editor
function EquipSet:it()
    local i = 0
    return function()
        i = i + 1
        if i <= 16 then
            local itemId = self[i-1]
            return i, itemId
        end
        --if itemId then
        --    return i, self[slot]  -- returns index as slot
        --end
        end
end

-- Deep copy
function EquipSet:copy()
    local args = {}
    for _, slot in ipairs(EquipSet.Slot.AllSlots) do
        table.insert(args, self[slot])
    end
    return EquipSet.new(table.unpack(args))
end

function EquipSet:save(equip_set_name)
    local CanEquipSetCondition = require('cylibs/conditions/can_equip_set')

    local equipSet = EquipSets:get({ name = equip_set_name, user_id = windower.ffxi.get_player().id }) or EquipSets({
        name = equip_set_name,
        user_id = windower.ffxi.get_player().id
    })
    for _, slot in ipairs(EquipSet.Slot.AllSlots) do
        equipSet[slot] = self[slot]
    end
    equipSet:save()

    if not Condition.check_conditions(L{ CanEquipSetCondition.new(equip_set_name) }, windower.ffxi.get_player().index) then
        addon_system_error(string.format("%s is not a valid set.", equip_set_name))
    end
end

-- Equality check
function EquipSet:__eq(other)
    if getmetatable(other) ~= EquipSet then return false end
    for _, slot in ipairs(EquipSet.Slot.AllSlots) do
        if self[slot] ~= other[slot] then return false end
    end
    return true
end

-- To string
function EquipSet:__tostring()
    local parts = {}
    for _, slot in ipairs(EquipSet.Slot.AllSlots) do
        local value = self[slot]
        if value ~= nil then
            local name = value == 65535 and 'Empty' or (Item:where({ id = value }, L{ 'en' })[1].en)
            table.insert(parts, string.format("%s: %s", slot, name))
        end
    end
    return string.format("EquipSet {\n  %s\n}", table.concat(parts, "\n  "))
end

return EquipSet]]
