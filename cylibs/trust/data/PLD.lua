Paladin = require('cylibs/entity/jobs/PLD')

local Trust = require('cylibs/trust/trust')
local PaladinTrust = setmetatable({}, {__index = Trust })
PaladinTrust.__index = PaladinTrust

local Healer = require('cylibs/trust/roles/healer')
local Puller = require('cylibs/trust/roles/puller')
local Buffer = require('cylibs/trust/roles/buffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Nuker = require('cylibs/trust/roles/nuker')
local Raiser = require('cylibs/trust/roles/raiser')
local Tank = require('cylibs/trust/roles/tank')

function PaladinTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Paladin.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Healer.new(action_queue, job),
		Raiser.new(action_queue, job),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings, job),
		Tank.new(action_queue, L{}, L{ Spell.new('Flash') })
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), PaladinTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function PaladinTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
	end)
end

function PaladinTrust:destroy()
	Trust.destroy(self)
end

function PaladinTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)
end

function PaladinTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return PaladinTrust



