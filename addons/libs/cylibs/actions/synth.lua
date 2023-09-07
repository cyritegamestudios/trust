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



