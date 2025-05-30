local Item = require('resources/resources').Item

local EquipSet = {}
EquipSet.__index = EquipSet
EquipSet.__type = "EquipSet"

EquipSet.Slot = {}
EquipSet.Slot.Main = "main"
EquipSet.Slot.Sub = "sub"
EquipSet.Slot.Range = "range"
EquipSet.Slot.Ammo = "ammo"
EquipSet.Slot.Head = "head"
EquipSet.Slot.Neck = "neck"
EquipSet.Slot.Ear1 = "left_ear"
EquipSet.Slot.Ear2 = "right_ear"
EquipSet.Slot.Body = "body"
EquipSet.Slot.Hands = "hands"
EquipSet.Slot.Ring1 = "right_ring"
EquipSet.Slot.Ring2 = "left_ring"
EquipSet.Slot.Back = "back"
EquipSet.Slot.Waist = "waist"
EquipSet.Slot.Legs = "legs"
EquipSet.Slot.Feet = "feet"
EquipSet.Slot.AllSlots = L{
    EquipSet.Slot.Main,
    EquipSet.Slot.Sub,
    EquipSet.Slot.Range,
    EquipSet.Slot.Ammo,
    EquipSet.Slot.Head,
    EquipSet.Slot.Neck,
    EquipSet.Slot.Ear1,
    EquipSet.Slot.Ear2,
    EquipSet.Slot.Body,
    EquipSet.Slot.Hands,
    EquipSet.Slot.Ring1,
    EquipSet.Slot.Ring2,
    EquipSet.Slot.Back,
    EquipSet.Slot.Waist,
    EquipSet.Slot.Legs,
    EquipSet.Slot.Feet
}

local bit = require('bit')  -- Only needed if bit isn't already available globally

local slot_bit_map = {
    [bit.lshift(1, 0)]  = EquipSet.Slot.Main,
    [bit.lshift(1, 1)]  = EquipSet.Slot.Sub,
    [bit.lshift(1, 2)]  = EquipSet.Slot.Range,
    [bit.lshift(1, 3)]  = EquipSet.Slot.Ammo,
    [bit.lshift(1, 4)]  = EquipSet.Slot.Head,
    [bit.lshift(1, 5)]  = EquipSet.Slot.Body,
    [bit.lshift(1, 6)]  = EquipSet.Slot.Hands,
    [bit.lshift(1, 7)]  = EquipSet.Slot.Legs,
    [bit.lshift(1, 8)]  = EquipSet.Slot.Feet,
    [bit.lshift(1, 9)]  = EquipSet.Slot.Neck,
    [bit.lshift(1, 10)] = EquipSet.Slot.Waist,
    [bit.lshift(1, 11)] = EquipSet.Slot.Ear1,       -- Left Ear
    [bit.lshift(1, 12)] = EquipSet.Slot.Ear2,       -- Right Ear
    [bit.lshift(1, 13)] = EquipSet.Slot.Ring2,      -- Left Ring
    [bit.lshift(1, 14)] = EquipSet.Slot.Ring1,      -- Right Ring
    [bit.lshift(1, 15)] = EquipSet.Slot.Back,
}


EquipSet.getSlotsForMask = function(mask)
    local slots = {}
    for bitmask, slot_name in pairs(slot_bit_map) do
        if bit.band(tonumber(mask), bitmask) ~= 0 then
            table.insert(slots, slot_name)
        end
    end
    return slots
end

function EquipSet.new(main, sub, range, ammo, head, neck, left_ear, right_ear, body, hands, left_ring, right_ring, back, waist, legs, feet)
    local self = setmetatable({}, EquipSet)

    self.main = main
    self.sub = sub
    self.range = range
    self.ammo = ammo
    self.head = head
    self.neck = neck
    self.left_ear = left_ear
    self.right_ear = right_ear
    self.body = body
    self.hands = hands
    self.left_ring = left_ring
    self.right_ring = right_ring
    self.back = back
    self.waist = waist
    self.legs = legs
    self.feet = feet

    return self
end

function EquipSet:getMain() return self.main end
function EquipSet:getSub() return self.sub end
function EquipSet:getRange() return self.range end
function EquipSet:getAmmo() return self.ammo end
function EquipSet:getHead() return self.head end
function EquipSet:getNeck() return self.neck end
function EquipSet:getEar1() return self.left_ear end
function EquipSet:getEar2() return self.right_ear end
function EquipSet:getBody() return self.body end
function EquipSet:getHands() return self.hands end
function EquipSet:getRing1() return self.left_ring end
function EquipSet:getRing2() return self.right_ring end
function EquipSet:getBack() return self.back end
function EquipSet:getWaist() return self.waist end
function EquipSet:getLegs() return self.legs end
function EquipSet:getFeet() return self.feet end

function EquipSet:it()
    local index = 0
    return function()
        index = index + 1
        local slot = EquipSet.Slot.AllSlots[index]
        if slot then
            return index, self[slot]
        end
    end
end

function EquipSet:copy()
    return EquipSet.new(self.main, self.sub, self.range, self.ammo, self.head, self.neck, self.left_ear, self.right_ear, self.body, self.hands, self.left_ring, self.right_ring, self.back, self.waist, self.legs, self.feet)
end

function EquipSet:__tostring()
    local parts = {}
    for slot in EquipSet.Slot.AllSlots:it() do
        local value = self[slot]
        if value ~= nil then
            local name = Item:where({ id = value }, L{ 'en' })[1].en
            if value == 65535 then
                name = 'Empty'
            end
            table.insert(parts, string.format("%s: %s", slot, name))
        end
    end
    return string.format("EquipSet {\n  %s\n}", table.concat(parts, "\n  "))
end

function EquipSet:__eq(other)
    if getmetatable(other) ~= EquipSet then
        return false
    end

    for slot in EquipSet.Slot.AllSlots:it() do
        if self[slot] ~= other[slot] then
            return false
        end
    end

    return true
end

return EquipSet
