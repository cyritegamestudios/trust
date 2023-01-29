require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local RangerTrust = setmetatable({}, {__index = Trust })
RangerTrust.__index = RangerTrust

local Buffer = require('cylibs/trust/roles/buffer')

function RangerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, nil, nil),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), RangerTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function RangerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
	end)
end

function RangerTrust:destroy()
	Trust.destroy(self)
end

function RangerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function RangerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return RangerTrust



