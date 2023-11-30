require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local DancerTrust = setmetatable({}, {__index = Trust })
DancerTrust.__index = DancerTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dancer = require('cylibs/entity/jobs/DNC')
local Healer = require('cylibs/trust/roles/healer')

function DancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Dancer.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities),
		Healer.new(action_queue, job),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), DancerTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function DancerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_cure_settings(new_trust_settings.CureSettings)

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
end

return DancerTrust



