require('tables')
require('lists')
require('logger')

WhiteMage = require('cylibs/entity/jobs/WHM')

local Trust = require('cylibs/trust/trust')
local WhiteMageTrust = setmetatable({}, {__index = Trust })
WhiteMageTrust.__index = WhiteMageTrust

local Barspeller = require('cylibs/trust/roles/barspeller')
local Healer = require('cylibs/trust/roles/healer')
local Raiser = require('cylibs/trust/roles/raiser')
local Debuffer = require('cylibs/trust/roles/debuffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')
local StatusRemover = require('cylibs/trust/roles/status_remover')
local WhiteMageTrustCommands = require('cylibs/trust/commands/WHM') -- keep this for dependency script

function WhiteMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = WhiteMage.new(trust_settings.CureSettings)
	local roles = S{
		Barspeller.new(action_queue, job),
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs, trust_settings.PartyBuffs),
		Debuffer.new(action_queue, trust_settings.Debuffs),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		ManaRestorer.new(action_queue, L{'Mystic Boon', 'Dagan', 'Spirit Taker', 'Moonlight'}, 40),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Healer.new(action_queue, job),
		StatusRemover.new(action_queue, job),
		Raiser.new(action_queue, job),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), WhiteMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function WhiteMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_cure_settings(new_trust_settings.CureSettings)

		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_job_abilities(new_trust_settings.JobAbilities)
			buffer:set_self_spells(new_trust_settings.SelfBuffs)
			buffer:set_party_spells(new_trust_settings.PartyBuffs)
		end

		local debuffer = self:role_with_type("debuffer")

		debuffer:set_debuff_spells(new_trust_settings.Debuffs)
	end)
end

function WhiteMageTrust:destroy()
	Trust.destroy(self)
end

function WhiteMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function WhiteMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return WhiteMageTrust