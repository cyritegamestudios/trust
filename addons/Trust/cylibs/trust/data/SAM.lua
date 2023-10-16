require('tables')
require('lists')
require('logger')

Samurai = require('cylibs/entity/jobs/SAM')

local Trust = require('cylibs/trust/trust')
local SamuraiTrust = setmetatable({}, {__index = Trust })
SamuraiTrust.__index = SamuraiTrust

local Buffer = require('cylibs/trust/roles/buffer')
local JobAbility = require('cylibs/actions/job_ability')
local job_util = require('cylibs/util/job_util')

function SamuraiTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Samurai.new()), SamuraiTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function SamuraiTrust:destroy()
	Trust.destroy(self)
end

function SamuraiTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
	end)
end

function SamuraiTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function SamuraiTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_tp()
end

function SamuraiTrust:check_tp()
	local tp = windower.ffxi.get_player().vitals.tp
	if tp < 1000 then
		if state.AutoBuffMode.value ~= 'Off' then
			if job_util.can_use_job_ability('Meditate') then
				self.action_queue:push_action(JobAbility.new(0, 0, 0, 'Meditate'))
			end
		end
	elseif tp > 1500 then
		if job_util.can_use_job_ability('Sekkanoki') then
			self.action_queue:push_action(JobAbility.new(0, 0, 0, 'Sekkanoki'))
		end
	end
end

return SamuraiTrust



