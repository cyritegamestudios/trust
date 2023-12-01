require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local DancerTrust = setmetatable({}, {__index = Trust })
DancerTrust.__index = DancerTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dancer = require('cylibs/entity/jobs/DNC')
local DisposeBag = require('cylibs/events/dispose_bag')
local FlourishAction = require('cylibs/actions/flourish')
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
	self.last_step_time = os.time()
	self.step_target_index = nil
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
	end)
end

function DancerTrust:on_role_added(role)
	if role:get_type() == "skillchainer" then
		self.dispose_bag:add(role:on_ready_weaponskill():addAction(function(weaponskill_name, _)
			if L{"Rudra's Storm", "Pyrrhic Kleos"}:contains(weaponskill_name) then
				if buff_util.is_any_buff_active(L{381,382,383,384,385,588}) then
					local flourish_action = FlourishAction.new('Building Flourish')
					flourish_action.priority = ActionPriority.highest

					self.action_queue:push_action(flourish_action, true)
				end

			end
		end), role:on_ready_weaponskill())
	end
end

function DancerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
	self.step_target_index = nil
end

function DancerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_steps()
end

function DancerTrust:check_steps()
	if os.time() - self.last_step_time < 10 or self.target_index == nil or player.status ~= 'Engaged' or self.step_target_index == self.target_index then
		return
	end
	local target = windower.ffxi.get_mob_by_index(self.target_index)
	if battle_util.is_valid_target(target.id) then
		self.last_step_time = os.time()
		self.step_target_index = self.target_index
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Box Step', target.index))
	end
end

return DancerTrust



