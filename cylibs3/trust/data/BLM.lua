require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local BlackMageTrust = setmetatable({}, {__index = Trust })
BlackMageTrust.__index = BlackMageTrust

function BlackMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, S{}, trust_settings.SelfBuffs),
		Debuffer.new(action_queue),
		Dispeler.new(action_queue),
		Nuker.new(action_queue)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), BlackMageTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_buff_time = os.time()

	return self
end

function BlackMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function BlackMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_mp()
end

function BlackMageTrust:check_mp()
	if windower.ffxi.get_player().vitals.mpp < 40 then
		if self.target_index and windower.ffxi.get_player().vitals.tp > 1000 then
			self.action_queue:push_action(WeaponSkillAction.new('Myrkr'), true)
		end
	end
end

return BlackMageTrust



