local Trust = require('cylibs/trust/trust')
local DancerTrust = setmetatable({}, {__index = Trust })
DancerTrust.__index = DancerTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dancer = require('cylibs/entity/jobs/DNC')
local DisposeBag = require('cylibs/events/dispose_bag')
local Healer = require('cylibs/trust/roles/healer')

function DancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Dancer.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities),
		Healer.new(action_queue, job),
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

		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_job_abilities(new_trust_settings.JobAbilities)
		end

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function DancerTrust:on_role_added(role)
	if L{"skillchainer", "spammer"}:contains(role:get_type()) then
		role:set_job_abilities(L{ JobAbility.new('Building Flourish'), JobAbility.new('Climactic Flourish') })
	end
end

function DancerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)
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



