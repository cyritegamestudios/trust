require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local DancerTrust = setmetatable({}, {__index = Trust })
DancerTrust.__index = DancerTrust


function DancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), DancerTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function DancerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function DancerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return DancerTrust



