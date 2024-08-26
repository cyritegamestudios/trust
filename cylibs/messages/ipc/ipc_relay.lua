local CommandMessage = require('cylibs/messages/command_message')
local EquipmentChangedMessage = require('cylibs/messages/equipment_changed_message')
local Event = require('cylibs/events/Luvent')
local GainBuffMessage = require('cylibs/messages/gain_buff_message')
local IpcConnection = require('cylibs/messages/ipc/ipc_connection')
local IpcMessage = require('cylibs/messages/ipc_message')
local LampUpdateMessage = require('cylibs/messages/lamp_update_message')
local logger = require('cylibs/logger/logger')
local LoseBuffMessage = require('cylibs/messages/lose_buff_message')
local MobUpdateMessage = require('cylibs/messages/mob_update_message')
local ZoneMessage = require('cylibs/messages/zone_message')

local IpcRelay = {}
IpcRelay.__index = IpcRelay
IpcRelay.__class = "IpcRelay"

state.IpcMode = M{['description'] = 'Send IPC Messages', 'All', 'Off', 'Send', 'Receive'}
state.IpcMode:set_description('All', "Okay, I'll send and receive IPC messages.")
state.IpcMode:set_description('Send', "Okay, I'll only send IPC messages.")
state.IpcMode:set_description('Receive', "Okay, I'll only receive IPC messages.")

-- Event called when an ipc message is received
function IpcRelay:on_message_received()
    return self.message_received
end

-- Event called when a new connection is established with another character
function IpcRelay:on_connected()
    return self.connected
end

function IpcRelay.new()
    local self = setmetatable({
    }, IpcRelay)

    self.connections = T{}
    self.events = {}
    self.events.ipc_message = windower.register_event('ipc message', function(message)
        if L{'All', 'Receive'}:contains(state.IpcMode.value) then
            local sender_name, message = message:match("(%S+)%s(.+)$")
            local ipc_message = IpcMessage.new(message)
            if ipc_message:is_valid() then
                --logger.notice(self.__class, "ipc message received", ipc_message:get_message())
                self:update_connection(sender_name)
                local message_type = ipc_message:get_type()
                if message_type == 'mob_update' then
                    self:on_message_received():trigger(MobUpdateMessage.deserialize(message))
                elseif message_type == 'gain_buff' then
                    self:on_message_received():trigger(GainBuffMessage.deserialize(message))
                elseif message_type == 'lose_buff' then
                    self:on_message_received():trigger(LoseBuffMessage.deserialize(message))
                elseif message_type == 'zone' then
                    self:on_message_received():trigger(ZoneMessage.deserialize(message))
                elseif message_type == 'command' then
                    self:on_message_received():trigger(CommandMessage.deserialize(message))
                elseif message_type == 'equipment_changed' then
                    self:on_message_received():trigger(EquipmentChangedMessage.deserialize(message))
                elseif message_type == 'lamp_update' then
                    self:on_message_received():trigger(LampUpdateMessage.deserialize(message))
                end
            end
        end
    end)
    self.events.tic = windower.register_event('time change', function()
        self:check_connections()
    end)

    self.message_received = Event.newEvent()
    self.connected = Event.newEvent()

    return self
end

function IpcRelay:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self.message_received:removeAllActions()
    self.connected:removeAllActions()
end

function IpcRelay:send_message(ipcMessage)
    if L{'All', 'Send'}:contains(state.IpcMode.value) then
        local message = "%s %s":format(windower.ffxi.get_player().name, ipcMessage:serialize())
        windower.send_ipc_message(message)
    end
end

function IpcRelay:update_connection(sender_name)
    if self.connections[sender_name] == nil then
        logger.notice("Now connected to", sender_name, "via IPC")
    end

    local connection = self.connections[sender_name] or IpcConnection.new(sender_name)
    connection:set_last_message_sent_time(os.time())
    if self.connections[sender_name] == nil then
        self:on_connected():trigger(sender_name)
    end
    self.connections[sender_name] = connection
end

function IpcRelay:check_connections()
    local connections_to_remove = L{}
    for sender_name, connection in pairs(self.connections) do
        --logger.notice("Last notice for", sender_name, "sent at", tostring(connection:get_last_message_sent_time()))
        if os.time() - connection:get_last_message_sent_time() > 2 then
            connections_to_remove:append(sender_name)
        end
    end
    for sender_name in connections_to_remove:it() do
        self.connections[sender_name] = nil
        logger.notice("Disconnected from", sender_name, "via IPC")
    end
end

function IpcRelay:is_connected(mob_name)
    return self.connections[mob_name]
end

function IpcRelay.shared()
    if ipc_relay == nil then
        ipc_relay = IpcRelay.new()
    end
    return ipc_relay
end

return IpcRelay



