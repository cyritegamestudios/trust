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



