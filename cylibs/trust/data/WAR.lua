Warrior = require('cylibs/entity/jobs/WAR')

local Trust = require('cylibs/trust/trust')
local WarriorTrust = setmetatable({}, {__index = Trust })
WarriorTrust.__index = WarriorTrust

function WarriorTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, nil, nil),
		Puller.new(action_queue, battle_settings.targets, nil, 'Provoke'),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Warrior.new()), WarriorTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function WarriorTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function WarriorTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return WarriorTrust



