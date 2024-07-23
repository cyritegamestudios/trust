local DarkKnight = require('cylibs/entity/jobs/DRK')

local Trust = require('cylibs/trust/trust')
local DarkKnightTrust = setmetatable({}, {__index = Trust })
DarkKnightTrust.__index = DarkKnightTrust

local Spell = require('cylibs/battle/spell')
local buff_util = require('cylibs/util/buff_util')

local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Puller = require('cylibs/trust/roles/puller')

function DarkKnightTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs),
		Debuffer.new(action_queue,trust_settings.Debuffs or L{}),
		Dispeler.new(action_queue, L{ Spell.new('Absorb-Attri') }, L{}, false),
		ManaRestorer.new(action_queue, L{'Entropy'}, L{}, 40),
		Puller.new(action_queue, battle_settings.targets, trust_settings.PullSettings.Abilities or L{ Spell.new('Absorb-STR'), Spell.new('Absorb-ACC'), Spell.new('Stone') }:compact_map()),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, DarkKnight.new()), DarkKnightTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function DarkKnightTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		buffer:set_job_abilities(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function DarkKnightTrust:on_deinit()
end

function DarkKnightTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)
end

function DarkKnightTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

function DarkKnightTrust:job_magic_burst(target_id, spell)
	Trust.job_magic_burst(self, target_id, spell)

	if spell.en == 'Drain III' and not buff_util.is_buff_active(buff_util.buff_id('Max HP Boost')) then
		local actions = L{
			JobAbilityAction.new(0, 0, 0, 'Nether Void'),
			WaitAction.new(0, 0, 0, 0.25),
			JobAbilityAction.new(0, 0, 0, 'Dark Seal'),
			WaitAction.new(0, 0, 0, 0.25),
			JobAbilityAction.new(0, 0, 0, 'Third Eye'),
			WaitAction.new(0, 0, 0, 0.25),
			SpellAction.new(0, 0, 0, spell.id, self.target_index, self:get_player())
		}
		self.action_queue:push_action(SequenceAction.new(actions, 'mb_'..spell.id), true)
	end
end

return DarkKnightTrust



