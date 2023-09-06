---------------------------
-- Trust file for Red Mage. In addition to base trust functionality, a Red Mage trust
-- will buff, debuff, heal, dispel, pull and skillchain.
-- @class module
-- @name RedMageTrust

RedMage = require('cylibs/entity/jobs/RDM')

local Trust = require('cylibs/trust/trust')
local RedMageTrust = setmetatable({}, {__index = Trust })
RedMageTrust.__index = RedMageTrust

local BattleStatTracker = require('cylibs/battle/battle_stat_tracker')
local Monster = require('cylibs/battle/monster')
local buff_util = require('cylibs/util/buff_util')

local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Healer = require('cylibs/trust/roles/healer')
local Puller = require('cylibs/trust/roles/puller')
local Raiser = require('cylibs/trust/roles/raiser')

state.AutoConvertMode = M{['description'] = 'Auto Convert Mode', 'Off', 'Auto'}

-------
-- Default initializer for a Red Mage trust.
-- @tparam T settings Settings
-- @tparam ActionQueue action_queue Action queue
-- @tparam T battle_settings Battle settings
-- @treturn RedMageTrust Red Mage trust
function RedMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = RedMage.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs, trust_settings.PartyBuffs),
		Debuffer.new(action_queue, trust_settings.Debuffs),
		Dispeler.new(action_queue, L{ Spell.new('Dispel') }),
		Healer.new(action_queue, job),
		Raiser.new(action_queue, job),
		Puller.new(action_queue, battle_settings.targets, 'Dia II', nil),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), RedMageTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.last_mp_check = os.time()

	return self
end

function RedMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)
		buffer:set_party_spells(new_trust_settings.PartyBuffs)

		local debuffer = self:role_with_type("debuffer")

		debuffer:set_debuff_spells(new_trust_settings.Debuffs)
	end)

	self.battle_stat_tracker = BattleStatTracker.new(windower.ffxi.get_player().id)
	self.battle_stat_tracker:monitor()
end

function RedMageTrust:on_deinit()
	self.battle_stat_tracker:destroy()
end

function RedMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index

	if self.battle_target then
		self.battle_target:destroy()
		self.battle_target = nil
	end

	if target_index then
		self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
		self.battle_target:monitor()
	end
end

function RedMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_accuracy()
	self:check_mp()
end

-------
-- Checks the player's mp. If it is less than 20% and AutoConvertMode is set to Auto, uses convert.
function RedMageTrust:check_mp()
	if state.AutoConvertMode.value == 'Off'
			or (os.time() - self.last_mp_check) < 8 then
		return
	end
	self.last_mp_check = os.time()

	if windower.ffxi.get_player().vitals.mpp < 20 then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Convert'), true)
	end
end

-------
-- Checks the player's accuracy. If it is less than 80%, casts Distract on the current battle target.
function RedMageTrust:check_accuracy()
	if self.target_index == nil then return end

	if self.battle_stat_tracker:get_accuracy() < 80 then
		local debuff = buff_util.debuff_for_spell(res.spells:with('name', 'Distract III').id)
		if debuff and not self.battle_target:has_debuff(debuff.id) then
			self.action_queue:push_action(SpellAction.new(0, 0, 0, res.spells:with('name', 'Distract III').id, self.target_index, self:get_player()), true)
		end
	end
end

return RedMageTrust