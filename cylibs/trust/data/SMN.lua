require('tables')
require('lists')
require('logger')

Summoner = require('cylibs/entity/jobs/SMN')

local SummonerTrust = setmetatable({}, {__index = Trust })
SummonerTrust.__index = SummonerTrust

local Avatar = require('cylibs/entity/avatar')

local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Summoner = require('cylibs/entity/jobs/SMN')

state.AutoAssaultMode = M{['description'] = 'Auto Assault Mode', 'Off', 'Auto'}
state.AutoAvatarMode = M{['description'] = 'Avatar Mode', 'Off', 'Ifrit', 'Ramuh', 'Shiva'}

function SummonerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, Summoner.new(), true),
		ManaRestorer.new(action_queue, L{'Myrkr', 'Spirit Taker'}, L{}, 40),
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Summoner.new()), SummonerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.party_buffs = trust_settings.PartyBuffs or L{}
	self.last_buff_time = os.time()
	self.last_avatar_check_time = os.time()
	self.is_auto_avatar_enabled = true

	return self
end

function SummonerTrust:on_init()
	Trust.on_init(self)

	if pet_util.has_pet() then
		self:update_avatar(pet_util.get_pet().id, pet_util.get_pet().name)
	end

	self:get_party():get_player():on_pet_change():addAction(
			function (_, pet_id, pet_name)
				self:update_avatar(pet_id, pet_name)
			end)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self.party_buffs = new_trust_settings.PartyBuffs or L{}

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function SummonerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function SummonerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_avatar()
	self:check_buffs()
	self:check_mp()

	if self.avatar then
		if not buff_util.is_buff_active(buff_util.buff_id("Avatar's Favor")) then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, "Avatar's Favor"))
		end
		if state.AutoAssaultMode.value ~= 'Off' and pet_util.pet_idle() and self.target_index and windower.ffxi.get_mob_by_index(self.target_index) then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Assault', self.target_index))
		end
	end
end

function SummonerTrust:check_avatar()
	if os.time() - self.last_avatar_check_time < 10 then
		return
	end
	self.last_avatar_check_time = os.time()

	if state.AutoBuffMode.value ~= 'Off' and self:get_inactive_buffs():length() > 0 then
		return
	end

	if state.AutoAvatarMode.value ~= 'Off' then
		if self.avatar then
			if self.avatar:get_mob().name ~= state.AutoAvatarMode.value then
				local actions = L{
					JobAbilityAction.new(0, 0, 0, 'Release'),
					WaitAction.new(0, 0, 0, 2),
					SpellAction.new(0, 0, 0, spell_util.spell_id(state.AutoAvatarMode.value), nil, self:get_player()),
					WaitAction.new(0, 0, 0, 2)
				}
				self.action_queue:push_action(SequenceAction.new(actions, 'summon_avatar'), true)
			end
		else
			local actions = L{
				SpellAction.new(0, 0, 0, spell_util.spell_id(state.AutoAvatarMode.value), nil, self:get_player()),
				WaitAction.new(0, 0, 0, 2)
			}
			self.action_queue:push_action(SequenceAction.new(actions, 'summon_avatar'), true)
		end
	end
end

function SummonerTrust:get_inactive_buffs()
	return self.party_buffs:filter(function(buff)
		return not buff_util.is_buff_active(buff_util.buff_for_job_ability(buff:get_job_ability_id()).id)
	end)
end

function SummonerTrust:check_buffs()
	if state.AutoBuffMode.value == 'Off'
			or (os.time() - self.last_buff_time) < 8 then
		return
	end

	for buff in self:get_inactive_buffs():it() do
		local recast_id = res.job_abilities:with('en', "Blood Pact: Ward").recast_id
		if windower.ffxi.get_ability_recasts()[recast_id] == 0 then
			local actions = L{}

			local avatar = self:get_job():get_avatar_name(buff:get_name())
			if pet_util.pet_name() ~= avatar then
				if pet_util.pet_name() ~= nil then
					actions:append(JobAbilityAction.new(0, 0, 0, 'Release'), true)
					actions:append(WaitAction.new(0, 0, 0, 1))
				end
				actions:append(SpellAction.new(0, 0, 0, spell_util.spell_id(avatar), nil, self:get_player()), true)
			end
			actions:append(WaitAction.new(0, 0, 0, 2))
			actions:append(BloodPactWardAction.new(0, 0, 0, buff:get_name()))
			actions:append(WaitAction.new(0, 0, 0, 2))

			local wardAction = SequenceAction.new(actions, 'blood_pact_ward')
			wardAction.max_duration = 15
			self.action_queue:push_action(wardAction, true)

			self.last_buff_time = os.time()
			self.is_auto_avatar_enabled = false
			return
		end
	end
end

function SummonerTrust:check_mp()
	if windower.ffxi.get_player().vitals.mpp < 20 then
		local actions = L{
			JobAbilityAction.new(0, 0, 0, 'Release'),
			SpellAction.new(0, 0, 0, spell_util.spell_id(self:get_job():get_spirit_for_current_day()), nil, self:get_player()),
			WaitAction.new(0, 0, 0, 2),
			JobAbilityAction.new(0, 0, 0, 'Elemental Siphon')
		}
		self.action_queue:push_action(SequenceAction.new(actions, 'elemental_siphon'), true)
	end
end

function SummonerTrust:update_avatar(pet_id, pet_name)
	if self.avatar then
		self.avatar:destroy()
		self.avatar = nil
	end
	if pet_id and L{
		'Shiva','Ramuh','Ifrit','Carbuncle','Fenrir',
		'Diabolos','Garuda','Leviathan','Titan','Siren',
		'Cait Sith','Fire Spirit','Ice Spirit','Air Spirit',
		'Earth Spirit','Thunder Spirit','Water Spirit',
		'Light Spirit','Dark Spirit'
	}:contains(pet_name) then
		self.avatar = Avatar.new(pet_id, self.action_queue)
		self.avatar:monitor()
	end

	local magic_burster = self:role_with_type("magicburster")
	if magic_burster then
		magic_burster:set_nuke_settings(self:get_trust_settings().NukeSettings)
	end
	local skillchainer = self:role_with_type("skillchainer")
	if skillchainer then
		skillchainer:update_abilities()
	end
end

return SummonerTrust



