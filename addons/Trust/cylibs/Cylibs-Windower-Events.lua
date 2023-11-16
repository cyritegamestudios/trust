local Event = require('cylibs/events/Luvent')
local packets = require('packets')

---------------------------
-- Windower global event handler. Requiring this in your addon will automatically create a global
-- event handler that registers a series of Windower event handlers that dispatch events to
-- the rest of the addon
-- @class module
-- @name WindowerEvents

local WindowerEvents = {}

-- Global list of handlers for all Windower events. Listen to events here.
WindowerEvents.Action = Event.newEvent()
WindowerEvents.ActionMessage = Event.newEvent()


local incoming_event_ids = S{
    0x028, -- data.incoming[0x028] = {name='Action',              description='Packet sent when an NPC is attacking.'}
    0x029, -- data.incoming[0x029] = {name='Action Message',      description='Packet sent for simple battle-related messages.'}
}

-- Jump table with a mapping of message_id to handler for that message_id
local incoming_event_dispatcher = {
    [0x028] = function(data)
        -- local packet = packets.parse('incoming', data)
        local act = windower.packets.parse_action(data)
        act.size = data:byte(5)
        WindowerEvents.Action:trigger(act)
    end,

    [0x029] = function(data)
        local packet = packets.parse('incoming', data)
        -- remap parameters
        local actor_id = packet['Actor']
        local target_id = packet['Target']
        local actor_index = packet['Actor Index']
        local target_index = packet['Target Index']
        local message_id = packet['Message']
        local param_1 = packet['Param 1']
        local param_2 = packet['Param 2']
        local param_3 = packet['_unknown1']
        WindowerEvents.ActionMessage:trigger(actor_id, target_id, actor_index,
            target_index, message_id, param_1, param_2, param_3)
    end,

}

--[[
    number id -- message ID
    string original -- original packet data (only used param right now, called data)
    string modified -- modified packet data, from other addons?
    bool injected -- was_injected?
    bool blocked -- was_blocked?
]]--
local function incoming_chunk_handler(id, data)
    if not incoming_event_ids[id] then return end -- if we don't care about the incoming_event_id, just return

    -- Check our dispatcher table for a function to handle this event_id
    local dispatch = incoming_event_dispatcher[id]
    -- If found, call handler to dispatch events
    if dispatch then
        -- call dispatch function from table (jump table implementation)
        dispatch(data)
    else
        return
    end

end

local IncomingChunkHandler = windower.register_event('incoming chunk', incoming_chunk_handler)

return WindowerEvents