local IpcMessage = require('cylibs/messages/ipc_message')

local GainBuffMessage = setmetatable({}, {__index = IpcMessage })
GainBuffMessage.__index = GainBuffMessage
GainBuffMessage.__class = "GainBuffMessage"

function GainBuffMessage.new(mob_id, buff_id)
    local self = setmetatable(IpcMessage.new(), GainBuffMessage)

    self.mob_id = tonumber(mob_id)
    self.buff_id = tonumber(buff_id)

    return self
end

function GainBuffMessage:get_command()
    return "gain_buff"
end

function GainBuffMessage:get_mob_id()
    return self.mob_id
end

function GainBuffMessage:get_buff_id()
    return self.buff_id
end

function GainBuffMessage:serialize()
    return "%s %s %f":format(self:get_command(), self:get_mob_id(), self:get_buff_id())
end

function GainBuffMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    return GainBuffMessage.new(ipc_message:get_args()[2], ipc_message:get_args()[3])
end

function GainBuffMessage:tostring()
    return "GainBuffMessage %s":format(self:get_message())
end

return GainBuffMessage



