---------------------------
-- Action representing interacting with an NPC.
-- @class module
-- @name NpcAction

local packets = require('packets')

local Action = require('cylibs/actions/action')
local NpcAction = setmetatable({}, { __index = Action })
NpcAction.__index = NpcAction
NpcAction.__class = "NpcAction"

-------
-- Default initializer for a NpcAction.
-- @tparam number npc_id NPC id
function NpcAction.new(npc_id)
    local self = setmetatable(Action.new(0, 0, 0), NpcAction)
    self.npc_id = npc_id
    return self
end

function NpcAction:perform()
    local npc = windower.ffxi.get_mob_by_id(self.npc_id)
    if not npc then
        self:complete(false)
        return
    end

    local packet = packets.new('outgoing', 0x01A, {
        ["Target"] = self.npc_id,
        ["Target Index"] = npc.index,
        ["Category"] = 0,
        ["Param"] = 0,
    })
    packets.inject(packet)

    self:complete(true)
end

function NpcAction:gettype()
    return "npcaction"
end

function NpcAction:is_equal(action)
    if action == nil or action.__class ~= NpcAction.__class then
        return false
    end
    return self.npc_id == action.npc_id
end

function NpcAction:tostring()
    local npc = windower.ffxi.get_mob_by_id(self.npc_id)
    return 'Interact with '..(npc and npc.name or tostring(self.npc_id))
end

return NpcAction
