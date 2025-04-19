Summoner = require('cylibs/entity/jobs/SMN')

local SummonerTrust = setmetatable({}, {__index = Trust })
SummonerTrust.__index = SummonerTrust

local Avatar = require('cylibs/entity/avatar')

local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Summoner = require('cylibs/entity/jobs/SMN')
local Buffer = require('cylibs/trust/roles/buffer')
local Frame = require('cylibs/ui/views/frame')
local Puller = require('cylibs/trust/roles/puller')
--local Nuker = require('cylibs/trust/roles/nuker')

state.AutoAssaultMode = M{['description'] = 'Auto Assault Mode', 'Off', 'Auto'}
state.AutoAvatarMode = M{['description'] = 'Avatar Mode', 'Off', 'Ifrit', 'Ramuh', 'Shiva', 'Garuda', 'Leviathan', 'Titan', 'Carbuncle', 'Diabolos', 'Fenrir', 'Siren', 'Cait Sith'}

function SummonerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Summoner.new()
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode, job),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job, true),
		--Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings, job),
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), SummonerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.party_buffs = trust_settings.BuffSettings.Gambits or L{}
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
		self.party_buffs = new_trust_settings.BuffSettings.Gambits or L{}
	end)
end

function SummonerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_avatar()
	self:check_mp()
end

function SummonerTrust:check_avatar()
	if os.time() - self.last_avatar_check_time < 10 or Condition.check_conditions(L{ InTownCondition.new() }, windower.ffxi.get_player().index) then
		return
	end
	self.last_avatar_check_time = os.time()

	if state.AutoBuffMode.value ~= 'Off' and self:get_inactive_buffs():length() > 0 then
		return
	end

	-- TODO: maybe use a mode delta to turn AutoAvatarMode Off when there are inactive buffs so I can use avatar gambits?
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
	return self.party_buffs:filter(function(gambit)
		return not buff_util.is_buff_active(buff_util.buff_for_job_ability(gambit:getAbility():get_job_ability_id()).id)
	end)
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
		'Cait Sith','FireSpirit','IceSpirit','AirSpirit',
		'EarthSpirit','ThunderSpirit','WaterSpirit',
		'LightSpirit','DarkSpirit'
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

function SummonerTrust:get_widget()
	local AvatarStatusWidget = require('ui/widgets/AvatarStatusWidget')
	local petStatusWidget = AvatarStatusWidget.new(
			Frame.new(132, 324, 125, 57),
			self:get_party():get_player(),
			windower.trust.ui.get_hud(),
			windower.trust.settings.get_job_settings('SMN'),
			state.MainTrustSettingsMode
	)
	return petStatusWidget, "pet"
end

return SummonerTrust



