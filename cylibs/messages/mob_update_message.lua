require('vectors')

local IpcMessage = require('cylibs/messages/ipc_message')

local MobUpdateMessage = setmetatable({}, {__index = IpcMessage })
MobUpdateMessage.__index = MobUpdateMessage
MobUpdateMessage.__class = "MobUpdateMessage"

function MobUpdateMessage.new(mob_name, x, y, z)
    local self = setmetatable(IpcMessage.new(), MobUpdateMessage)

    self.mob_name = mob_name

    self.position = vector.zero(3)
    self.position[1] = x
    self.position[2] = y
    self.position[3] = z

    return self
end

function MobUpdateMessage:get_command()
    return "mob_update"
end

function MobUpdateMessage:get_mob_name()
    return self.mob_name
end

function MobUpdateMessage:get_position()
    return self.position
end

function MobUpdateMessage:serialize()
    return "%s %s %f %f %f":format(self:get_command(), self:get_mob_name(), self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function MobUpdateMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    return MobUpdateMessage.new(ipc_message:get_args()[2], ipc_message:get_args()[3], ipc_message:get_args()[4], ipc_message:get_args()[5])
end

function MobUpdateMessage:tostring()
    return "MobUpdateMessage %s":format(self:get_message())
end

return MobUpdateMessage



