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
