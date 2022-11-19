require('tables')
require('lists')
require('logger')

RedMage = require('cylibs/entity/jobs/RDM')

local Trust = require('cylibs/trust/trust')
local RedMageTrust = setmetatable({}, {__index = Trust })
RedMageTrust.__index = RedMageTrust

local BattleStatTracker = require('cylibs/battle/battle_stat_tracker')

function RedMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = RedMage.new()
	local roles = S{
		Buffer.new(action_queue, S{'Composure'}, trust_settings.SelfBuffs, trust_settings.PartyBuffs),
		Debuffer.new(action_queue, trust_settings.Debuffs),
		Healer.new(action_queue, job),
		Dispeler.new(action_queue),
		Puller.new(action_queue, battle_settings.targets, 'Dia III', nil),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), RedMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function RedMageTrust:on_init()
	Trust.on_init(self)

	self.battle_stat_tracker = BattleStatTracker.new(windower.ffxi.get_player().id)
	self.battle_stat_tracker:monitor()
end

function RedMageTrust:destroy()
	Trust.destroy(self)

	self.battle_stat_tracker:destroy()
end

function RedMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function RedMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_accuracy()

	if windower.ffxi.get_player().vitals.mpp < 20 then
		--self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Convert'), true)
		return
	end
end

function RedMageTrust:check_accuracy()
	if self.battle_stat_tracker:get_accuracy() < 80 then
		--self.action_queue:push_action(SpellAction.new(0, 0, 0, res.spells:with('name', 'Distract III').id, self.target_index, self:get_player()), true)
	end
end

return RedMageTrust