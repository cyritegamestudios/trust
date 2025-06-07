WhiteMage = require('cylibs/entity/jobs/WHM')

local Trust = require('cylibs/trust/trust')
local WhiteMageTrust = setmetatable({}, {__index = Trust })
WhiteMageTrust.__index = WhiteMageTrust

local Barspeller = require('cylibs/trust/roles/barspeller')
local Healer = require('cylibs/trust/roles/healer_v2')
local Debuffer = require('cylibs/trust/roles/debuffer')
local DisposeBag = require('cylibs/events/dispose_bag')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')

function WhiteMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = WhiteMage.new(trust_settings.CureSettings)
	local roles = S{
		Healer.new(action_queue, trust_settings.CureSettings, job),
		StatusRemover.new(action_queue, job),
		Barspeller.new(action_queue, job),
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Debuffer.new(action_queue, trust_settings.DebuffSettings, job),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings, job),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), WhiteMageTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.dispose_bag = DisposeBag.new()

	return self
end

function WhiteMageTrust:on_init()
	Trust.on_init(self)

	self.dispose_bag:add(self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_cure_settings(new_trust_settings.CureSettings)

		local debuffer = self:role_with_type("debuffer")
		debuffer:set_debuff_settings(new_trust_settings.DebuffSettings)

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end), self:on_trust_settings_changed())

	self.dispose_bag:add(self:get_party():get_player():on_gain_buff():addAction(function(_, buff_id)
		local buff_name = buff_util.buff_name(buff_id)
		if buff_name == 'Afflatus Solace' then
			self:get_job():set_afflatus_mode(WhiteMage.Afflatus.Solace)
		elseif buff_name == 'Afflatus Misery' then
			self:get_job():set_afflatus_mode(WhiteMage.Afflatus.Misery)
		end
	end, self:get_party():get_player():on_gain_buff()))
end

function WhiteMageTrust:destroy()
	Trust.destroy(self)

	self.dispose_bag:destroy()
end

function WhiteMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function WhiteMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return WhiteMageTrust