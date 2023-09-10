require('tables')
require('logger')

local IpcMessage = require('cylibs/messages/ipc_message')

local FollowTargetMessage = setmetatable({}, {__index = IpcMessage })
FollowTargetMessage.__index = FollowTargetMessage

function FollowTargetMessage.new(message)
	local self = setmetatable(IpcMessage.new(message), FollowTargetMessage)
	local args = self:get_args()
	
	self.leader = args[2]
	self.follower = args[3]
	
	return self
end

function FollowTargetMessage:get_command()
	return "follow"
end

function FollowTargetMessage:get_leader()
	return self.leader
end

function FollowTargetMessage:get_follower()
	return self.follower
end

function FollowTargetMessage:tostring()
  return "FollowTargetMessage %s":format(self:get_message())
end

return FollowTargetMessage



