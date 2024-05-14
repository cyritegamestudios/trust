Dragoon = require('cylibs/entity/jobs/DRG')

local Trust = require('cylibs/trust/trust')
local DragoonTrust = setmetatable({}, {__index = Trust })
DragoonTrust.__index = DragoonTrust


function DragoonTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Dragoon.new()), DragoonTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_jump_time = os.time()

	return self
end

function DragoonTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function DragoonTrust:destroy()
	Trust.destroy(self)
end

function DragoonTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function DragoonTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_wyvern()
	self:jump()
end

function DragoonTrust:check_wyvern()
	if not pet_util.has_pet() then
		if job_util.can_use_job_ability('Call Wyvern') then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Call Wyvern'), true)
		end
	end
end

function DragoonTrust:jump()
	if self.target_index == nil then return end

	if state.AutoEnmityReductionMode.value ~= 'Off' and self:get_player():get_mob().hpp < 50 then
		if job_util.can_use_job_ability('Super Jump') then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Super Jump', self.target_index))
		end
	else
		if os.time() - self.last_jump_time > 5 then
			local monster = windower.ffxi.get_mob_by_index(self.target_index)
			if monster.hpp < 50 then
				local jump_abilities = L{'High Jump','Spirit Jump','Soul Jump'}
				for jump_ability in jump_abilities:it() do
					if job_util.can_use_job_ability(jump_ability) then
						self.last_jump_time = os.time()
						self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, jump_ability, self.target_index))
						return
					end
				end
			end
		end
	end
end

return DragoonTrust



