Dragoon = require('cylibs/entity/jobs/DRG')

local Trust = require('cylibs/trust/trust')
local DragoonTrust = setmetatable({}, {__index = Trust })
DragoonTrust.__index = DragoonTrust


function DragoonTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Dragoon.new()), DragoonTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_jump_time = os.time()

	return self
end

function DragoonTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function DragoonTrust:destroy()
	Trust.destroy(self)
end

function DragoonTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function DragoonTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return DragoonTrust



