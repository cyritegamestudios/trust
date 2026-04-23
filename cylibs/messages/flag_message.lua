local IpcMessage = require('cylibs/messages/ipc_message')

local FlagMessage = setmetatable({}, {__index = IpcMessage })
FlagMessage.__index = FlagMessage
FlagMessage.__class = "FlagMessage"

function FlagMessage.new(key, value)
    local self = setmetatable(IpcMessage.new(), FlagMessage)

    self.key = key
    self.value = value

    return self
end

function FlagMessage:get_command()
    return "flag"
end

function FlagMessage:get_key()
    return self.key
end

function FlagMessage:get_value()
    return self.value
end

function FlagMessage:serialize()
    return "%s %s %s":format(self:get_command(), self:get_key(), self:get_value())
end

function FlagMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    local key = ipc_message:get_args()[2]
    local value = ipc_message:get_args()[3]

    return FlagMessage.new(key, value)
end

function FlagMessage:tostring()
    return "FlagMessage %s":format(self:get_message())
end

return FlagMessage
