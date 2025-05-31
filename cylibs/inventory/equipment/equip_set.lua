local bit = require('bit')
local Item = require('resources/resources').Item

local EquipSet = {}
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
EquipSet.Slot.AllSlots = L{}
local slot_bit_map = {}

for _, slot in ipairs(slot_definitions) do
    local mask = bit.lshift(1, slot.bit)
    EquipSet.Slot[slot.name:gsub("^%l", string.upper)] = slot.name -- e.g. Slot.Main = "main"
    table.insert(EquipSet.Slot.AllSlots, slot.name)
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

-- Allow indexed access using bitmask numbers
EquipSet.__index = function(t, k)
    if type(k) == 'number' and slot_bit_map[bit.lshift(1, k)] then
        return rawget(t, slot_bit_map[bit.lshift(1, k)])
    end
    return rawget(EquipSet, k) or rawget(t, k)
end

-- Iterator
function EquipSet:it()
    local i = 0
    return function()
        i = i + 1
        local slot = EquipSet.Slot.AllSlots[i]
        if slot then return i, self[slot] end
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

return EquipSet
