BlueMage = require('cylibs/entity/jobs/BLU')

local Trust = require('cylibs/trust/trust')
local BlueMageTrust = setmetatable({}, {__index = Trust })
BlueMageTrust.__index = BlueMageTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Healer = require('cylibs/trust/roles/healer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')
local Tank = require('cylibs/trust/roles/tank')

function BlueMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = BlueMage.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Dispeler.new(action_queue, L{ Spell.new('Blank Gaze') }, L{}, true),
		Healer.new(action_queue, job),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{ 'Burst Affinity' }, job, true),
		ManaRestorer.new(action_queue, L{}, L{ Spell.new('Magic Hammer'), Spell.new('MP Drainkiss') }, 40),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings),
		Tank.new(action_queue, L{}, L{ Spell.new('Geist Wall'), Spell.new('Sheep Song') }),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), BlueMageTrust)
	return self
end

function BlueMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_cure_settings(new_trust_settings.CureSettings)

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)

	WindowerEvents.BlueMagic.SpellsChanged:addAction(function()
		local buffer = self:role_with_type("buffer")
		buffer:set_buff_settings(self:get_trust_settings().BuffSettings)
	end)
end

return BlueMageTrust



