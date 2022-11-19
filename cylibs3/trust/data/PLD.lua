require('tables')
require('lists')
require('logger')

Paladin = require('cylibs/entity/jobs/PLD')

local Trust = require('cylibs/trust/trust')
local PaladinTrust = setmetatable({}, {__index = Trust })
PaladinTrust.__index = PaladinTrust

function PaladinTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Paladin.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs, S{}),
		Healer.new(action_queue, job),
		Raiser.new(action_queue, job),
		Puller.new(action_queue, battle_settings.targets, 'Flash', nil),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), PaladinTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function PaladinTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function PaladinTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return PaladinTrust



