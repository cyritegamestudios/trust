local Trust = require('cylibs/trust/trust')
local BlackMageTrust = setmetatable({}, {__index = Trust })
BlackMageTrust.__index = BlackMageTrust

local BlackMage = require('cylibs/entity/jobs/BLM')
local BlackMageTrustCommands = require('cylibs/trust/commands/BLM') -- keep this for dependency script
local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')
local Sleeper = require('cylibs/trust/roles/sleeper')

function BlackMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = BlackMage.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs),
		Debuffer.new(action_queue, trust_settings.Debuffs),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{ 'Cascade', 'Manawell' }, job),
		ManaRestorer.new(action_queue, L{'Myrkr', 'Spirit Taker', 'Moonlight'}, L{}, 40),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, battle_settings.targets, L{ Spell.new('Burn') }),
		Sleeper.new(action_queue, L{ Spell.new('Sleepga'), Spell.new('Sleepga II') }, 4)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), BlackMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function BlackMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_job_abilities(new_trust_settings.JobAbilities)
			buffer:set_self_spells(new_trust_settings.SelfBuffs)
			buffer:set_party_spells(new_trust_settings.PartyBuffs)
		end

		local debuffer = self:role_with_type("debuffer")
		if debuffer then
			debuffer:set_debuff_spells(new_trust_settings.Debuffs)
		end

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)
end

function BlackMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function BlackMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return BlackMageTrust



