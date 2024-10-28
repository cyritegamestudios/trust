BlueMage = require('cylibs/entity/jobs/BLU')

local Trust = require('cylibs/trust/trust')
local BlueMageTrust = setmetatable({}, {__index = Trust })
BlueMageTrust.__index = BlueMageTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Healer = require('cylibs/trust/roles/healer')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')

function BlueMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = BlueMage.new()
	local roles = S{
		Buffer.new(action_queue, S{}, trust_settings.SelfBuffs),
		Dispeler.new(action_queue, L{ Spell.new('Blank Gaze') }, L{}, true),
		Healer.new(action_queue, job),
		ManaRestorer.new(action_queue, L{}, L{ Spell.new('Magic Hammer'), Spell.new('MP Drainkiss') }, 40),
		Puller.new(action_queue, trust_settings.PullSettings.Targets, L{ Spell.new('Glutinous Dart') }:compact_map())
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), BlueMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function BlueMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_cure_settings(new_trust_settings.CureSettings)

		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_job_abilities(new_trust_settings.JobAbilities)
			buffer:set_self_spells(new_trust_settings.SelfBuffs)
			buffer:set_party_spells(new_trust_settings.PartyBuffs)
		end

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)

	WindowerEvents.BlueMagic.SpellsChanged:addAction(function()
		local buffer = self:role_with_type("buffer")
		buffer:set_self_spells(self:get_trust_settings().SelfBuffs)
		buffer:set_party_spells(self:get_trust_settings().PartyBuffs)
	end)
end

function BlueMageTrust:destroy()
	Trust.destroy(self)
end

function BlueMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function BlueMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return BlueMageTrust



