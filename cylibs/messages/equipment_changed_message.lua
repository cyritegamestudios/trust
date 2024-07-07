local IpcMessage = require('cylibs/messages/ipc_message')

local EquipmentChangedMessage = setmetatable({}, {__index = IpcMessage })
EquipmentChangedMessage.__index = EquipmentChangedMessage
EquipmentChangedMessage.__class = "EquipmentChangedMessage"

function EquipmentChangedMessage.new(mob_id, main_weapon_id, ranged_weapon_id)
    local self = setmetatable(IpcMessage.new(), EquipmentChangedMessage)

    self.mob_id = tonumber(mob_id)
    self.main_weapon_id = tonumber(main_weapon_id or 0)
    self.ranged_weapon_id = tonumber(ranged_weapon_id or 0)

    return self
end

function EquipmentChangedMessage:get_command()
    return "equipment_changed"
end

function EquipmentChangedMessage:get_mob_id()
    return self.mob_id
end

function EquipmentChangedMessage:get_main_weapon_id()
    return self.main_weapon_id
end

function EquipmentChangedMessage:get_ranged_weapon_id()
    return self.ranged_weapon_id
end

function EquipmentChangedMessage:serialize()
    return "%s %s %f %f":format(self:get_command(), self:get_mob_id(), self:get_main_weapon_id(), self:get_ranged_weapon_id())
end

function EquipmentChangedMessage.deserialize(message)
    local ipc_message = IpcMessage.new(message)

    return EquipmentChangedMessage.new(ipc_message:get_args()[2], ipc_message:get_args()[3], ipc_message:get_args()[4])
end

function EquipmentChangedMessage:tostring()
    return "EquipmentChangedMessage %s":format(self:get_message())
end

return EquipmentChangedMessage



