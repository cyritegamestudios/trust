local IpcMessage = require('cylibs/messages/ipc_message')

local CommandMessage = setmetatable({}, {__index = IpcMessage })
CommandMessage.__index = CommandMessage
CommandMessage.__class = "CommandMessage"

function CommandMessage.new(windower_command)
    local self = setmetatable(IpcMessage.new(), CommandMessage)

    self.windower_command = windower_command

    return self
end

function CommandMessage:get_command()
    return "command"
end

function CommandMessage:get_windower_command()
    return self.windower_command
end

function CommandMessage:serialize()
    return "%s %s":format(self:get_command(), self:get_windower_command())
end

function CommandMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    local windower_command = ""
    for arg in ipc_message:get_args():slice(2, ipc_message:get_args():length()):it() do
        windower_command = windower_command..arg..' '
    end
    return CommandMessage.new(windower_command)
end

function CommandMessage:tostring()
    return "CommandMessage %s":format(self:get_message())
end

return CommandMessage



