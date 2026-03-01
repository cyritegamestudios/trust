local IpcMessage = require('cylibs/messages/ipc_message')

local TargetChangeMessage = setmetatable({}, {__index = IpcMessage })
TargetChangeMessage.__index = TargetChangeMessage
TargetChangeMessage.__class = "TargetChangeMessage"

function TargetChangeMessage.new(player_name, target_index)
    local self = setmetatable(IpcMessage.new(), TargetChangeMessage)

    self.player_name = player_name
    self.target_index = tonumber(target_index or 0)

    return self
end

function TargetChangeMessage:get_command()
    return "target_change"
end

function TargetChangeMessage:get_player_name()
    return self.player_name
end

function TargetChangeMessage:get_target_index()
    return self.target_index
end

function TargetChangeMessage:serialize()
    return "%s %s %d":format(self:get_command(), self:get_player_name(), self:get_target_index())
end

function TargetChangeMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    return TargetChangeMessage.new(ipc_message:get_args()[2], ipc_message:get_args()[3])
end

function TargetChangeMessage:tostring()
    return "TargetChangeMessage %s":format(self:get_message())
end

return TargetChangeMessage
