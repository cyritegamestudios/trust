require('tables')
require('lists')
require('logger')

Samurai = require('cylibs/entity/jobs/SAM')

local Trust = require('cylibs/trust/trust')
local SamuraiTrust = setmetatable({}, {__index = Trust })
SamuraiTrust.__index = SamuraiTrust

function SamuraiTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, S{}),
		Skillchainer.new(action_queue, L{'auto', 'prefer'})
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Samurai.new()), SamuraiTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function SamuraiTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function SamuraiTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return SamuraiTrust



