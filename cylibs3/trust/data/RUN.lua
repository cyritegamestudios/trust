require('tables')
require('lists')
require('logger')

RuneFencer = require('cylibs/entity/jobs/RUN')

local Trust = require('cylibs/trust/trust')
local RuneFencerTrust = setmetatable({}, {__index = Trust })
RuneFencerTrust.__index = RuneFencerTrust

state.AutoRuneMode = M{['description'] = 'Auto Rune Mode', 'Off', 'Auto'}

function RuneFencerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs, S{}),
		Puller.new(action_queue, battle_settings.targets, 'Flash', nil),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, RuneFencer.new()), RuneFencerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.rune_last_used = os.time()

	return self
end

function RuneFencerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function RuneFencerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_runes()
end

function RuneFencerTrust:check_runes()
	if os.time() - self.rune_last_used < 5 then
		return
	end

	if state.AutoRuneMode.value == 'Auto' and windower.ffxi.get_ability_recasts()[10] == 0 then -- or 92
		local current_runes = self:get_job():get_current_runes()

		local rune_set = L{{Name='Ignis', Amount=3}}

		for rune in rune_set:it() do
			local runesActive = current_runes:filter(function(rune_name) return rune_name == rune.Name end)
			if #runesActive < rune.Amount then
				self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, rune.Name), true)
				self.rune_last_used = os.time()
				return
			end
		end
	end
end

return RuneFencerTrust



