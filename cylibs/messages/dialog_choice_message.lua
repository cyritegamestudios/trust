--[[Copyright © 2019, Cyrite

Path v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

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



