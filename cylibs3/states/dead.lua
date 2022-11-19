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
require('vectors')

local Action = {}
Action.__index = Action

-- Constructor for vectors. Optionally provide dimension n, to avoid computing the dimension from the table.
function Action.new(x, y, z)
  local self = setmetatable({
      x = x;
      y = y;
      z = z;
	  cancelled = false;
    }, Action)
  return self
end

function Action:can_perform()
	if self:is_cancelled() then
		return false
	end
	return true
end

function Action:perform(completion)
	self.completion = completion
end

function Action:complete(success)
	self.completed = true

	if self.completion ~= nil then
		self.completion(success)
		self.completion = nil
	end
end

function Action:cancel()
	notice("Cancelling %s":format(self:tostring()))

	self.cancelled = true

	if self.completion ~= nil then
		self.completion(false)
		self.completion = nil
	end
end

function Action:get_position()
	local v = vector.zero(3)

	v[1] = self.x
	v[2] = self.y
	v[3] = self.z

	return v
end

function Action:gettype()
	return "action"
end

function Action:getrawdata()
	local res = {}
	
	res.action = {}
	res.action.x = self.x
	res.action.y = self.y
	res.action.z = self.z
	
	return res
end

function Action:is_cancelled()
	return self.cancelled
end

function Action:is_completed()
	return self.completion == nil
end

function Action:copy()
	return Action.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function Action:tostring()
  return "Action %d, %d":format(self:get_position()[1], self:get_position()[2])
end

return Action



