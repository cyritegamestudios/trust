require('tables')
require('lists')
require('logger')

BlueMage = require('cylibs/entity/jobs/BLU')

local Trust = require('cylibs/trust/trust')
local BlueMageTrust = setmetatable({}, {__index = Trust })
BlueMageTrust.__index = BlueMageTrust

function BlueMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, S{}, trust_settings.SelfBuffs),
		Dispeler.new(action_queue),
		Nuker.new(action_queue),
		Skillchainer.new(action_queue, L{'auto', 'prefer', 'am'}),
		Puller.new(action_queue, battle_settings.targets, 'Glutinous Dart', nil)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, BlueMage.new()), BlueMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function BlueMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index

	if self.target_index == nil then
		self.is_defense_down_active = false
		--[[self.action_queue:push_action(SequenceAction.new(L{
			JobAbilityAction.new(0, 0, 0, 'Chain Affinity'),
			WaitAction.new(0, 0, 0, 2),
			JobAbilityAction.new(0, 0, 0, 'Efflux')
		}, 'chain-affinity'), true)]]
	end
end

function BlueMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	if self.target_index then
		self:check_debuffs()
		--self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Provoke'), self.target_index)
	end
end

function BlueMageTrust:check_debuffs()
	if not self.is_defense_down_active then
		local target = windower.ffxi.get_mob_by_index(self.target_index)
		if target.distance:sqrt() < 10 then
			self.is_defense_down_active = true
			self.action_queue:push_action(SpellAction.new(0, 0, 0, res.spells:with('name', 'Sweeping Gouge').id, self.target_index, self:get_player()), true)
		end

	end
end

return BlueMageTrust



