local Trust = require('cylibs/trust/trust')
local MonkTrust = setmetatable({}, {__index = Trust })
MonkTrust.__index = MonkTrust

local BattleStatTracker = require('cylibs/battle/battle_stat_tracker')

local Buffer = require('cylibs/trust/roles/buffer')

function MonkTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, nil, nil),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), MonkTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function MonkTrust:on_init()
	Trust.on_init(self)

	self.battle_stat_tracker = BattleStatTracker.new(windower.ffxi.get_player().id)
	self.battle_stat_tracker:monitor()

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		buffer:set_job_abilities(new_trust_settings.JobAbilities)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function MonkTrust:destroy()
	Trust.destroy(self)

	self.battle_stat_tracker:destroy()
end

function MonkTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function MonkTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_accuracy()
end

function MonkTrust:check_accuracy()
	if self.battle_stat_tracker:get_accuracy() < 80 then
		if not buff_util.is_buff_active(buff_util.buff_id('Focus'))
				and job_util.can_use_job_ability('Focus') then
			self.action_queue:push_action(SequenceAction.new(L{
				JobAbilityAction.new(0, 0, 0, 'Focus'),
				WaitAction.new(0, 0, 0, 1),
			}, 'focus'), true)
		end
	end
end


return MonkTrust



