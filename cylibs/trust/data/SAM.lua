Samurai = require('cylibs/entity/jobs/SAM')

local Trust = require('cylibs/trust/trust')
local SamuraiTrust = setmetatable({}, {__index = Trust })
SamuraiTrust.__index = SamuraiTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Puller = require('cylibs/trust/roles/puller')

function SamuraiTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Samurai.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Puller.new(action_queue, trust_settings.PullSettings),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), SamuraiTrust)

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
	end)
end

function SamuraiTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function SamuraiTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return SamuraiTrust



