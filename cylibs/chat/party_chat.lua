local IpcMessage = require('cylibs/messages/ipc_message')
local WaitAction = require('cylibs/actions/wait')
local PartyChatMessageAction = require('cylibs/actions/party_chat_message')
local PartyChatMessage = require('cylibs/messages/party_chat_message')

local PartyChat = {}
PartyChat.__index = PartyChat

state.PartyChatMode = M{['description'] = 'Party Chat Mode', 'Private', 'Party', 'Off'}
state.PartyChatMode:set_description('Private', "Okay, only you'll be able to see my messages.")
state.PartyChatMode:set_description('Party', "Okay, I'll send messages to party chat.")

function PartyChat.new(ipcEnabled)
    local self = setmetatable({}, PartyChat)

    self.ipcEnabled = ipcEnabled
    self.message_queue = ActionQueue.new(nil, false, 10)
    self.message_last_sent = {}
    self.events = {}
    if ipcEnabled then
        self.events.ipc_message = windower.register_event('ipc message', function(message)
            if not message then
                return
            end
            if state.PartyChatMode.value == 'Off' then
                return
            end
            local ipcMessage = IpcMessage.new(message)
            if ipcMessage:get_args():length() > 0 and ipcMessage:get_args()[1] == 'party_chat' then
                local partyChatMessage = PartyChatMessage.new(message)
                addon_message(260, "(%s) %s":format(partyChatMessage:get_sender_name() or "?", partyChatMessage:get_chat_message()))
            end
        end)
    end

    return self
end

function PartyChat:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
        self.events = {}
    end
    if self.message_queue then
        self.message_queue:destroy()
        self.message_queue = nil
    end
    self.message_last_sent = {}
end

function PartyChat:should_throttle(throttle_key, throttle_duration)
    if not throttle_key or not throttle_duration or throttle_duration <= 0 then
        return false
    end
    local now = os.time()
    -- Prune expired entries so the table stays bounded. Each entry carries
    -- its own expiry, so a short-duration call cannot evict a key that was
    -- recorded with a longer duration.
    for key, expires_at in pairs(self.message_last_sent) do
        if now >= expires_at then
            self.message_last_sent[key] = nil
        end
    end
    local expires_at = self.message_last_sent[throttle_key]
    if not expires_at then
        return false
    end
    return now < expires_at
end

function PartyChat:add_to_chat(sender_name, message, throttle_key, throttle_duration, is_local_only, party)
    if not message then
        return
    end
    sender_name = sender_name or "?"
    if self:should_throttle(throttle_key, throttle_duration) then
        return
    end
    if throttle_key and throttle_duration then
        self.message_last_sent[throttle_key] = os.time() + throttle_duration
    end

    if state.PartyChatMode.value == 'Private' or is_local_only then
        addon_message(260, "(%s) %s":format(sender_name, message))

        if self.ipcEnabled and not is_local_only then
            windower.send_ipc_message("party_chat %s %s":format(sender_name, message))
        end
    elseif state.PartyChatMode.value == 'Party' then
        local message_action = SequenceAction.new(L{
            PartyChatMessageAction.new(message, party),
            -- Wait 1.25s after each /p so back-to-back chat lines
            -- do not collide: the first line goes to party chat
            -- and the second errors when two windower.chat.input
            -- calls land in rapid succession. The wait runs on a
            -- timer (async), it does not block the caller.
            WaitAction.new(0, 0, 0, 1.25),
        }, 'party_chat_'..message)
        self.message_queue:push_action(message_action, true)
    end
end

return PartyChat