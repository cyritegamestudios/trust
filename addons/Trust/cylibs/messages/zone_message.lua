local IpcMessage = require('cylibs/messages/ipc_message')

local ZoneMessage = setmetatable({}, {__index = IpcMessage })
ZoneMessage.__index = ZoneMessage

--- Create a new ZoneMessage instance.
-- @tparam string mob_name Name of the mob
-- @tparam string zone_id The id of the old zone (see res/zones.lua)
-- @tparam string zone_line The zone line
-- @tparam string zone_type The zone type
-- @tparam number x The last x-coordinate in the old zone
-- @tparam number y The last y-coordinate in the old zone
-- @tparam number z The last z-coordinate in the old zone
-- @treturn ZoneMessage A new ZoneMessage
function ZoneMessage.new(mob_name, zone_id, zone_line, zone_type, x, y, z)
	local self = setmetatable(IpcMessage.new(), ZoneMessage)

	self.mob_name = mob_name
	self.zone_id = zone_id
	self.zone_line = zone_line
	self.zone_type = zone_type
	self.x = x
	self.y = y
	self.z = z
	
	return self
end

function ZoneMessage:get_command()
	return "zone"
end

function ZoneMessage:get_mob_name()
	return self.mob_name
end

function ZoneMessage:get_zone_id()
	return tonumber(self.zone_id)
end

function ZoneMessage:get_zone_line()
	return self.zone_line or 0
end

function ZoneMessage:get_zone_type()
	return self.zone_type or 0
end

function ZoneMessage:get_position()
	local position = vector.zero(3)
	position[1] = self.x
	position[2] = self.y
	position[3] = self.z
	return position
end

function ZoneMessage:serialize()
	return "%s %s %d %d %d %f %f %f":format(self:get_command(), self:get_mob_name(), self:get_zone_id(), self:get_zone_line(), self:get_zone_type(), self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function ZoneMessage.deserialize(message)
	local ipc_message = IpcMessage.new(message)

	return ZoneMessage.new(ipc_message:get_args()[2], ipc_message:get_args()[3], ipc_message:get_args()[4], ipc_message:get_args()[5], ipc_message:get_args()[6], ipc_message:get_args()[7], ipc_message:get_args()[8])
end

function ZoneMessage:tostring()
  return "ZoneMessage %s":format(self:get_message())
end

return ZoneMessage



