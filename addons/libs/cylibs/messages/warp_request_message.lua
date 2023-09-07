require('tables')
require('logger')

local res = require('resources')

local IpcMessage = require('cylibs/messages/ipc_message')

local WarpRequestMessage = setmetatable({}, {__index = IpcMessage })
WarpRequestMessage.__index = WarpRequestMessage

function WarpRequestMessage.new(message)
	local self = setmetatable(IpcMessage.new(message), WarpRequestMessage)
	local args = self:get_args()
	notice("msg %s":format(message))
	self.zone_name = res.zones[args[2]].en
	self.homepoint_number = args[3]
	
	return self
end

function WarpRequestMessage:get_command()
	return "warprequest"
end

function WarpRequestMessage:get_zone_name()
	return self.zone_name
end

function WarpRequestMessage:get_homepoint_number()
	return self.homepoint_number
end

function WarpRequestMessage:tostring()
  return "WarpRequestMessage %s":format(self:get_message())
end

return WarpRequestMessage



