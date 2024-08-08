local IpcMessage = require('cylibs/messages/ipc_message')

local LampUpdateMessage = setmetatable({}, {__index = IpcMessage })
LampUpdateMessage.__index = LampUpdateMessage
LampUpdateMessage.__class = "LampUpdateMessage"

function LampUpdateMessage.new(lamp_index, lamp_id, order_id)
    local self = setmetatable(IpcMessage.new(), LampUpdateMessage)

    self.lamp_index = lamp_index
    self.lamp_id = lamp_id
    self.order_id = order_id

    return self
end

function LampUpdateMessage:get_command()
    return "lamp_update"
end

function LampUpdateMessage:get_lamp_index()
    return self.lamp_index
end

function LampUpdateMessage:get_lamp_id()
    return self.lamp_id
end

function LampUpdateMessage:get_order_id()
    return self.order_id
end

function LampUpdateMessage:serialize()
    return "%s %f %f %f":format(self:get_command(), self:get_lamp_index(), self:get_lamp_id(), self:get_order_id())
end

function LampUpdateMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    return LampUpdateMessage.new(tonumber(ipc_message:get_args()[2]), tonumber(ipc_message:get_args()[3]), tonumber(ipc_message:get_args()[4]))
end

function LampUpdateMessage:tostring()
    return "LampUpdateMessage %s":format(self:get_message())
end

return LampUpdateMessage



