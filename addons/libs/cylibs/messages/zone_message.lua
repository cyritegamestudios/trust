require('tables')
require('logger')

local IpcMessage = require('cylibs/messages/ipc_message')

local ZoneMessage = setmetatable({}, {__index = IpcMessage })
ZoneMessage.__index = ZoneMessage

-- Example message: zone target_name new_id old_id
function ZoneMessage.new(message)
	local self = setmetatable(IpcMessage.new(message), ZoneMessage)
	local args = self:get_args()
	
	self.target_name = args[2]
	self.new_id = args[3]
	self.old_id = args[4]
	
	return self
end

function ZoneMessage:get_command()
	return "zone"
end

function ZoneMessage:get_target_name()
	return self.target_name
end

function ZoneMessage:get_old_zone_id()
	return self.old_id
end

function ZoneMessage:get_new_zone_id()
	return self.new_id
end

function ZoneMessage:tostring()
  return "ZoneMessage %s":format(self:get_message())
end

return ZoneMessage



