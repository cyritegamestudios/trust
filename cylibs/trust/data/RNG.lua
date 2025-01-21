local Trust = require('cylibs/trust/trust')
local RangerTrust = setmetatable({}, {__index = Trust })
RangerTrust.__index = RangerTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Puller = require('cylibs/trust/roles/puller')
local Ranger = require('cylibs/entity/jobs/RNG')
local RangedAttack = require('cylibs/battle/ranged_attack')
local Shooter = require('cylibs/trust/roles/shooter')

function RangerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Ranger.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Puller.new(action_queue, trust_settings.PullSettings),
		Shooter.new(action_queue, trust_settings.Shooter),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), RangerTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function RangerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local shooter = self:role_with_type("shooter")
		if shooter then
			shooter:set_shooter_settings(new_trust_settings.Shooter)
		end
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



