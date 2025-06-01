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
