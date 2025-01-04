local Trust = require('cylibs/trust/trust')
local MonkTrust = setmetatable({}, {__index = Trust })
MonkTrust.__index = MonkTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Monk = require('cylibs/entity/jobs/MNK')

function MonkTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Monk.new()), MonkTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function MonkTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function MonkTrust:destroy()
	Trust.destroy(self)
end

function MonkTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)
end

function MonkTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return MonkTrust



