require('tables')
require('logger')

local IpcMessage = require('cylibs/messages/ipc_message')

local DialogChoiceMessage = setmetatable({}, {__index = IpcMessage })
DialogChoiceMessage.__index = DialogChoiceMessage

function DialogChoiceMessage.new(message)
	local self = setmetatable(IpcMessage.new(message), DialogChoiceMessage)
	local args = self:get_args()
	
	self.target_id = args[2]
	self.option_index = args[3]
	if type(args[4]) == "string" then
		if args[4] == "true" then
			self.automated_message = true
		else
			self.automated_message = false
		end
	else 
		self.automated_message = args[4]
	end
	self.zone_id = args[5]
	self.menu_id = args[6]
	
	return self
end

function DialogChoiceMessage:get_command()
	return "dialogchoice"
end

function DialogChoiceMessage:get_target_id()
	return self.target_id
end

function DialogChoiceMessage:get_option_index()
	return self.option_index
end

function DialogChoiceMessage:get_automated_message()
	return self.automated_message
end

function DialogChoiceMessage:get_zone_id()
	return self.zone_id
end

function DialogChoiceMessage:get_menu_id()
	return self.menu_id
end

function DialogChoiceMessage:tostring()
  return "DialogChoiceMessage %s":format(self:get_message())
end

return DialogChoiceMessage



