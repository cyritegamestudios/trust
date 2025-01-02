local DarkKnight = require('cylibs/entity/jobs/DRK')

local Trust = require('cylibs/trust/trust')
local DarkKnightTrust = setmetatable({}, {__index = Trust })
DarkKnightTrust.__index = DarkKnightTrust

local Spell = require('cylibs/battle/spell')

local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')

function DarkKnightTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = DarkKnight.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings),
		Debuffer.new(action_queue,trust_settings.DebuffSettings),
		Dispeler.new(action_queue, L{ Spell.new('Absorb-Attri') }, L{}, false),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		ManaRestorer.new(action_queue, L{'Entropy'}, L{}, 40),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings.Targets, trust_settings.PullSettings.Abilities or L{ Spell.new('Absorb-STR'), Spell.new('Absorb-ACC'), Spell.new('Stone') }:compact_map()),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), DarkKnightTrust)
	return self
end

function DarkKnightTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local debuffer = self:role_with_type("debuffer")
		debuffer:set_debuff_settings(new_trust_settings.DebuffSettings)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)
end

function DarkKnightTrust:on_deinit()
end

return DarkKnightTrust



