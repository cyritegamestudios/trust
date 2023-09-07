require('tables')
require('logger')

local IpcMessage = require('cylibs/messages/ipc_message')

local UnfollowTargetMessage = setmetatable({}, {__index = IpcMessage })
UnfollowTargetMessage.__index = UnfollowTargetMessage

function UnfollowTargetMessage.new(message)
	local self = setmetatable(IpcMessage.new(message), UnfollowTargetMessage)
	local args = self:get_args()
	
	self.leader = args[2]
	self.follower = args[3]
	
	return self
end

function UnfollowTargetMessage:get_command()
	return "unfollow"
end

function UnfollowTargetMessage:get_leader()
	return self.leader
end

function UnfollowTargetMessage:get_follower()
	return self.follower
end

function UnfollowTargetMessage:tostring()
  return "UnfollowTargetMessage %s":format(self:get_message())
end

return UnfollowTargetMessage



