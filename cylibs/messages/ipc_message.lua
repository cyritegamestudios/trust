local IpcMessage = {}
IpcMessage.__index = IpcMessage

function IpcMessage.new(message)
  local self = setmetatable({
      message = message;
    }, IpcMessage)
  return self
end

function IpcMessage:is_valid()
	return self:get_args():length() > 0
end

function IpcMessage:get_command()
	return "ipc"
end

function IpcMessage:get_type()
	return self:get_args()[1]
end

function IpcMessage:get_message()
	return self.message or self:serialize()
end

function IpcMessage:get_args()
	local args = L{}
	for arg in self:get_message():gmatch("%S+") do 
		args:append(arg)
	end
	return args
end

function IpcMessage:serialize()
	return self.message
end

function IpcMessage:deserialize(message)
	return IpcMessage.new(message)
end


function IpcMessage:tostring()
  return "IpcMessage %s":format(self:get_message())
end

return IpcMessage



