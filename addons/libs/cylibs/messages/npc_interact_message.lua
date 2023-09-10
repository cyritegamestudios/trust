require('tables')
require('logger')

local IpcMessage = require('cylibs/messages/ipc_message')

local NpcInteractMessage = setmetatable({}, {__index = IpcMessage })
NpcInteractMessage.__index = NpcInteractMessage

function NpcInteractMessage.new(message)
	local self = setmetatable(IpcMessage.new(message), NpcInteractMessage)
	local args = self:get_args()
	
	self.npc_id = args[2]
	self.category = args[3]
	
	return self
end

function NpcInteractMessage:get_command()
	return "npcinteract"
end

function NpcInteractMessage:get_npc_id()
	return self.npc_id
end

function NpcInteractMessage:get_category()
	return self.category
end

function NpcInteractMessage:tostring()
  return "NpcInteractMessage %s":format(self:get_message())
end

return NpcInteractMessage



