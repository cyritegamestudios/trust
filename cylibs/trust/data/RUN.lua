RuneFencer = require('cylibs/entity/jobs/RUN')

local Trust = require('cylibs/trust/trust')
local RuneFencerTrust = setmetatable({}, {__index = Trust })
RuneFencerTrust.__index = RuneFencerTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Puller = require('cylibs/trust/roles/puller')
local Tank = require('cylibs/trust/roles/tank')
local Frame = require('cylibs/ui/views/frame')

state.AutoRuneMode = M{['description'] = 'Auto Rune Mode', 'Off', 'Tenebrae', 'Lux', 'Ignis', 'Gelus', 'Flabra', 'Tellus', 'Sulpor', 'Unda'}

function RuneFencerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = RuneFencer.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Puller.new(action_queue, trust_settings.PullSettings),
		Tank.new(action_queue, L{}, L{ Spell.new('Sheep Song'), Spell.new('Geist Wall'), Spell.new('Flash') })
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), RuneFencerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.rune_last_used = os.time() - 5

	return self
end

function RuneFencerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
	end)
end

function RuneFencerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_runes()
end

function RuneFencerTrust:check_runes()
	if os.time() - self.rune_last_used < 5 then
		return
	end

	if state.AutoRuneMode.value ~= 'Off' and windower.ffxi.get_ability_recasts()[10] == 0 then -- or 92
		local current_runes = self:get_job():get_current_runes()

		local rune_set = L{{Name=state.AutoRuneMode.value, Amount=self:get_job():get_max_num_runes()}}

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

function RuneFencerTrust:get_widget()
	local RuneFencerWidget = require('ui/widgets/RuneFencerWidget')
	local runeFencerWidget = RuneFencerWidget.new(Frame.new(4, 294, 125, 57), self)
	return runeFencerWidget, "job"
end

return RuneFencerTrust



