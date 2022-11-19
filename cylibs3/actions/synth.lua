--[[Copyright © 2019, Cyrite

Farm v1.0.0

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

require('actions')
require('vectors')
require('math')
require('logger')
require('lists')

local packets = require('packets')
local SynthResult = require('cylibs/synth/synthresult')

local Action = require('cylibs/actions/action')
local SynthAction = setmetatable({}, {__index = Action })
SynthAction.__index = SynthAction

function SynthAction.new()
	local self = setmetatable(Action.new(0, 0, 0), SynthAction)
 	return self
end

function SynthAction:can_perform()
	if self:is_cancelled() then
		return false
	end
	return true
end

function SynthAction:perform(completion)
	FarmAction.perform(self, completion)

	windower.ffxi.run(false)
	windower.ffxi.follow()

	self.observer_id = -1
	self.observer_id = windower.register_event('incoming chunk', function(id, data)
		-- Synthesis end
		if id == 0x6F then
			local synth_result = SynthResult.new(data)
		
			notice("%s":format(synth_result:tostring()))
		
			-- Success
			if synth_result:is_success() then
				self:complete(true)
		
			-- Critical failure
			elseif synth_result:is_failure() and synth_result:lost_items():length() > 0 then
				self:complete(true)
			end
		end
	end)
end

function SynthAction:complete(success)
	if self.observer_id and self.observer_id ~= -1 then
		windower.unregister_event(self.observer_id)
	end

	FarmAction.complete(self, success)
end

function SynthAction:gettargetid()
	return self.target_id
end

function SynthAction:gettype()
	return "synthaction"
end

function SynthAction:getrawdata()
	local res = {}
	res.synthaction = {}
	return res
end

function SynthAction:tostring()
    return "SynthAction"
end

return SynthAction



