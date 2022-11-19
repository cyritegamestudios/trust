require('tables')
require('lists')
require('logger')

DarkKnight = require('cylibs/entity/jobs/DRK')

local Trust = require('cylibs/trust/trust')
local DarkKnightTrust = setmetatable({}, {__index = Trust })
DarkKnightTrust.__index = DarkKnightTrust

local BattleStatTracker = require('cylibs/battle/battle_stat_tracker')

function DarkKnightTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs),
		Puller.new(action_queue, battle_settings.targets, 'Stone', nil),
		Skillchainer.new(action_queue, L{'auto', 'prefer'})
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, DarkKnight.new()), DarkKnightTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.battle_stat_tracker = BattleStatTracker.new(windower.ffxi.get_player().id)
	self.battle_stat_tracker:monitor()

	return self
end

function DarkKnightTrust:destroy()
	Trust.destroy(self)

	self.battle_stat_tracker:destroy()
end

function DarkKnightTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index

	self.battle_stat_tracker:reset()

	if self.target_index == nil then
		if buff_util.is_buff_active(buff_util.buff_id('Max HP Boost')) and not buff_util.is_buff_active(buff_util.buff_id('Dread Spikes')) then
			self.action_queue:push_action(SequenceAction.new(L{
				WaitAction.new(0, 0, 0, 3),
				SpellAction.new(0, 0, 0, spell_util.spell_id('Dread Spikes'), nil, self:get_player()),
				WaitAction.new(0, 0, 0, 5)
			}, 'dread-spikes'), true)
		end
	end
end

function DarkKnightTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_accuracy()
end

function DarkKnightTrust:check_accuracy()
	if self.battle_stat_tracker:get_accuracy() < 80 then
		if not buff_util.is_buff_active(self:get_job():buff_for_absorb_spell('Absorb-ACC').id)
				and spell_util.can_cast_spell(spell_util.spell_id('Absorb-ACC')) then
			self.action_queue:push_action(SequenceAction.new(L{
				SpellAction.new(0, 0, 0, spell_util.spell_id('Absorb-ACC'), self.target_index, self:get_player()),
				WaitAction.new(0, 0, 0, 1),
			}, 'absorb-acc'), true)
		end
	end
end

function DarkKnightTrust:job_magic_burst(target_id, spell)
	Trust.job_magic_burst(self, target_id, spell)

	if spell.en == 'Drain III' and not buff_util.is_buff_active(buff_util.buff_id('Max HP Boost')) then
		local actions = L{
			JobAbilityAction.new(0, 0, 0, 'Nether Void'),
			WaitAction.new(0, 0, 0, 0.25),
			JobAbilityAction.new(0, 0, 0, 'Dark Seal'),
			WaitAction.new(0, 0, 0, 0.25),
			JobAbilityAction.new(0, 0, 0, 'Third Eye'),
			WaitAction.new(0, 0, 0, 0.25),
			SpellAction.new(0, 0, 0, spell.id, self.target_index, self:get_player())
		}
		self.action_queue:push_action(SequenceAction.new(actions, 'mb_'..spell.id), true)
	end
end

return DarkKnightTrust



