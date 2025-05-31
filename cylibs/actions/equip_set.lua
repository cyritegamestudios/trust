---------------------------
-- Equips an equip set.
-- @class module
-- @name EquipSetAction

local packets = require('packets')

local Action = require('cylibs/actions/action')
local EquipSetAction = setmetatable({}, {__index = Action })
EquipSetAction.__index = EquipSetAction

function EquipSetAction.new(equipSet)
    local conditions = L{
        NotCondition.new(L{HasBuffsCondition.new(L{'encumbrance'}, 1)}, windower.ffxi.get_player().index),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), EquipSetAction)
    self.equipSet = equipSet
    return self
end

function EquipSetAction:perform()
    local data = {}

    local delta = player.party:get_player():get_current_equip_set():delta(self.equipSet)

    -- TODO: still need to check to make sure that it isn't trying to equip gear it can't use (or bad combos of main/sub or range/ammo)

    local i = 1
    for slot_id = 0, T(res.slots):keyset():length() do
        if delta[slot_id] then
            print(delta[slot_id])
            local bag, index = windower.trust:get_inventory():find(delta[slot_id]) -- NOTE: this has an issue if you are trying to equip two items with the same name
            if bag == nil or index == -1 then
                addon_system_error(string.format("Unable to find %d.", delta[slot_id]))
                self:complete(false)
                return
            end
            data[string.format("Inventory Index %d", i)] = index
            data[string.format("Equipment Slot %d", i)] = slot_id
            data[string.format("Bag %d", i)] = res.bags:with('api', bag.name).id
            data[string.format("_padding1 %d", i)] = 0
            i = i + 1
        end
    end

    if i > 1 then
        data.Count = i - 1

        local p = packets.new('outgoing', 0x051, data, data.Count)
        p._raw = packets.build(p)

        --for key, value in pairs(data) do
        --    print(key, value)
        --end

        packets.inject(p)

        self:complete(true)
    else
        self:complete(true)
    end
end

function EquipSetAction:gettype()
    return "equipsetaction"
end

function EquipSetAction:getrawdata()
    local res = {}
    return res
end

function EquipSetAction:tostring()
    return 'Equipping'
end

return EquipSetAction



