Warrior = require('cylibs/entity/jobs/WAR')

local Trust = require('cylibs/trust/trust')
local WarriorTrust = setmetatable({}, {__index = Trust })
WarriorTrust.__index = WarriorTrust

local Puller = require('cylibs/trust/roles/puller')
local Buffer = require('cylibs/trust/roles/buffer')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local Tank = require('cylibs/trust/roles/tank')

function WarriorTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, nil, nil),
		Puller.new(action_queue, battle_settings.targets, L{ JobAbility.new('Provoke') }),
		Tank.new(action_queue, L{ 'Provoke' }, L{})
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Warrior.new()), WarriorTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function WarriorTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_abilities(new_trust_settings.JobAbilities)
	end)
end

function WarriorTrust:destroy()
	Trust.destroy(self)
end

function WarriorTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function WarriorTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return WarriorTrust



