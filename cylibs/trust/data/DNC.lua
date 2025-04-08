local Trust = require('cylibs/trust/trust')
local DancerTrust = setmetatable({}, {__index = Trust })
DancerTrust.__index = DancerTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dancer = require('cylibs/entity/jobs/DNC')
local DisposeBag = require('cylibs/events/dispose_bag')
local Healer = require('cylibs/trust/roles/healer')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')

function DancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Dancer.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		Healer.new(action_queue, job),
		Puller.new(action_queue, trust_settings.PullSettings, job),
		StatusRemover.new(action_queue, job),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), DancerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.dispose_bag = DisposeBag.new()

	return self
end

function DancerTrust:destroy()
	Trust.destroy(self)

	self.dispose_bag:destroy()
end

function DancerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_cure_settings(new_trust_settings.CureSettings)
	end)

	self:get_party():get_player():on_gain_buff():addAction(function(_, buff_id)
		local buff_name = buff_util.buff_name(buff_id)
		if buff_name == 'Saber Dance' then
			if state.AutoHealMode.value ~= 'Off' or state.AutoStatusRemovalMode.value ~= 'Off' then
				addon_system_error("Unable to use waltzes while Saber Dance is active.")
			end
		end
	end)
end

function DancerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_finishing_moves()
end

function DancerTrust:check_finishing_moves()
	if job_util.can_use_job_ability('No Foot Rise') and not self:get_job():has_finishing_moves() then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'No Foot Rise'), true)
	end
end

return DancerTrust



