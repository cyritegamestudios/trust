require('tables')
require('lists')
require('logger')

WhiteMage = require('cylibs/entity/jobs/WHM')

local Trust = require('cylibs/trust/trust')
local WhiteMageTrust = setmetatable({}, {__index = Trust })
WhiteMageTrust.__index = WhiteMageTrust

local Healer = require('cylibs/trust/roles/healer')
local Raiser = require('cylibs/trust/roles/raiser')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')

function WhiteMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = WhiteMage.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs, trust_settings.PartyBuffs),
		Debuffer.new(action_queue, trust_settings.Debuffs),
		Nuker.new(action_queue, 10),
		Healer.new(action_queue, job),
		Raiser.new(action_queue, job),
		--Evader.new(settings, action_queue)
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

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)
		buffer:set_party_spells(new_trust_settings.PartyBuffs)

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

	if self.target_index then
		--self.action_queue:push_action(SpellAction.new(0, 0, 0, res.spells:with('name', 'Dia II').id, self.target_index), true)
	end
end

function WhiteMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return WhiteMageTrust