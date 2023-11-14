require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local DancerTrust = setmetatable({}, {__index = Trust })
DancerTrust.__index = DancerTrust

local Buffer = require('cylibs/trust/roles/buffer')

function DancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), DancerTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function DancerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_job_abilities(new_trust_settings.JobAbilities)
		end
	end)
end

function DancerTrust:destroy()
	Trust.destroy(self)
end

function DancerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function DancerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	if windower.ffxi.get_player().vitals.hpp < 40 then
		local actions = L{
			JobAbilityAction.new(0, 0, 0, 'Curing Waltz III'),
			WaitAction.new(0, 0, 0, 2.0),
		}
		self.action_queue:push_action(SequenceAction.new(actions, 'healer_waltz'), true)
	end
end

return DancerTrust



