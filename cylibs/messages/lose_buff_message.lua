local IpcMessage = require('cylibs/messages/ipc_message')

local LoseBuffMessage = setmetatable({}, {__index = IpcMessage })
LoseBuffMessage.__index = LoseBuffMessage
LoseBuffMessage.__class = "LoseBuffMessage"

function LoseBuffMessage.new(mob_id, buff_id)
    local self = setmetatable(IpcMessage.new(), LoseBuffMessage)

    self.mob_id = tonumber(mob_id)
    self.buff_id = tonumber(buff_id)

    return self
end

function LoseBuffMessage:get_command()
    return "lose_buff"
end

function LoseBuffMessage:get_mob_id()
    return self.mob_id
end

function LoseBuffMessage:get_buff_id()
    return self.buff_id
end

function LoseBuffMessage:serialize()
    return "%s %s %f":format(self:get_command(), self:get_mob_id(), self:get_buff_id())
end

function LoseBuffMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    return LoseBuffMessage.new(ipc_message:get_args()[2], ipc_message:get_args()[3])
end

function LoseBuffMessage:tostring()
    return "LoseBuffMessage %s":format(self:get_message())
end

return LoseBuffMessage



