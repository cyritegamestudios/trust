local Trust = require('cylibs/trust/trust')
local BlackMageTrust = setmetatable({}, {__index = Trust })
BlackMageTrust.__index = BlackMageTrust

local BlackMage = require('cylibs/entity/jobs/BLM')
local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')
local Sleeper = require('cylibs/trust/roles/sleeper')
local Frame = require('cylibs/ui/views/frame')

function BlackMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = BlackMage.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Debuffer.new(action_queue, trust_settings.DebuffSettings, job),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{ 'Manawell' }, job, false),
		ManaRestorer.new(action_queue, L{'Myrkr', 'Spirit Taker', 'Moonlight'}, L{}, 40),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings),
		Sleeper.new(action_queue, L{ Spell.new('Sleepga'), Spell.new('Sleepga II') }, 4)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), BlackMageTrust)
	return self
end

function BlackMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local debuffer = self:role_with_type("debuffer")
		debuffer:set_debuff_settings(new_trust_settings.DebuffSettings)

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)
end

function BlackMageTrust:get_widget()
	local BlackMageWidget = require('ui/widgets/BlackMageWidget')
	local blackMageWidget = BlackMageWidget.new(Frame.new(40, 294, 125, 57), self:get_party():get_player(), self)
	return blackMageWidget, 'job'
end

return BlackMageTrust



