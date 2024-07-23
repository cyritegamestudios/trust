require('tables')
require('lists')
require('logger')

Puppetmaster = require('cylibs/entity/jobs/PUP')

local DisposeBag = require('cylibs/events/dispose_bag')
local JobAbilityAction = require('cylibs/actions/job_ability')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local buff_util = require('cylibs/util/buff_util')
local party_util = require('cylibs/util/party_util')
local pet_util = require('cylibs/util/pet_util')

local Trust = require('cylibs/trust/trust')
local PuppetmasterTrust = setmetatable({}, {__index = Trust })
PuppetmasterTrust.__index = PuppetmasterTrust
PuppetmasterTrust.__class = "PuppetmasterTrust"

Automaton = require('cylibs/entity/automaton')

local Dispeler = require('cylibs/trust/roles/dispeler')
local Buffer = require('cylibs/trust/roles/buffer')

state.AutoAssaultMode = M{['description'] = 'Auto Assault Mode', 'Off', 'Auto'}
state.AutoManeuverMode = M{['description'] = 'Auto Maneuver Mode', 'Off', 'Auto'}
state.AutoPetMode = M{['description'] = 'Auto Pet Mode', 'Off', 'Auto'}
state.AutoRepairMode = M{['description'] = 'Auto Repair Mode', 'Auto', 'Off'}

function PuppetmasterTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, S{}, S{}),
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Dark Maneuver', L{ HasAttachmentsCondition.new(L{ 'regulator', 'disruptor' }), NotCondition.new(L{ HasBuffCondition.new('Dark Maneuver', windower.ffxi.get_player().index) }, windower.ffxi.get_player().index) }, L{}, 'me') }, false),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Puppetmaster.new()), PuppetmasterTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.defaultManeuvers = trust_settings.DefaultManeuvers
	self.overdriveManeuvers = trust_settings.OverdriveManeuvers
	self.maneuver_last_used = os.time()
	self.economizer_last_used = os.time()
	self.dispose_bag = DisposeBag.new()

	state.ManeuverMode = M{['description'] = 'Maneuver Mode', T(T(trust_settings.DefaultManeuvers):keyset())}

	return self
end

function PuppetmasterTrust:on_init()
	Trust.on_init(self)

	if pet_util.has_pet() then
		self:update_automaton(pet_util.get_pet().id, pet_util.get_pet().name)
	end

	self.dispose_bag:add(self:get_player():on_pet_change():addAction(
			function (_, pet_id, pet_name)
				self:update_automaton(pet_id, pet_name)
			end), self:get_player():on_pet_change())

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self.defaultManeuvers = new_trust_settings.DefaultManeuvers
		self.overdriveManeuvers = new_trust_settings.OverdriveManeuvers

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)

	state.ManeuverMode:on_state_change():addAction(function(_, new_value)
		if self.defaultManeuvers[new_value] then
			self.maneuver_set = self.defaultManeuvers[new_value]
		end
	end)
end

function PuppetmasterTrust:on_deinit()
	self:update_automaton(nil, nil)

	state.ManeuverMode:on_state_change():removeAllActions()

	self.dispose_bag:destroy()
end

function PuppetmasterTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
	self.target_change_time = os.time()
end

function PuppetmasterTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_automaton()

	logger.notice(self.__class, 'tic', 'pet status', self.automaton and self.automaton:get_name() or 'no pet')

	if self.automaton then
		self:check_maneuvers()
		self:check_deploy()
	end
end

function PuppetmasterTrust:check_deploy()
	if self.target_index == nil then
		return
	end

	local target = windower.ffxi.get_mob_by_index(self.target_index)

	if state.AutoAssaultMode.value == 'Off' or target == nil or target.hpp <= 0 or not self.automaton:is_idle()
			or (os.time() - self.target_change_time < 2) or not party_util.party_claimed(target.id) then
		return
	end

	local deploy_action = JobAbilityAction.new(0, 0, 0, 'Deploy', self.target_index)
	deploy_action.priority = ActionPriority.highest
	self.action_queue:push_action(deploy_action, true)
end

function PuppetmasterTrust:check_automaton()
	if self.automaton:is_mage() then
		self:check_restore_mp()
	end
end

function PuppetmasterTrust:check_restore_mp()
	local vitals = self.automaton:get_vitals()
	if vitals.mpp < 40 and self.automaton:has_attachment('mana converter') and (os.time() - self.economizer_last_used) > 90 then
		self.economizer_last_used = os.time()
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Dark Maneuver'), true)
		return
	elseif vitals.hpp > 80 and vitals.mpp < 25 and job_util.can_use_job_ability('Deactivate') then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Deactivate'), true)
	end
end

function PuppetmasterTrust:check_maneuvers()
	if os.time() - self.maneuver_last_used < 5 then
		return
	end

	if state.AutoManeuverMode.value == 'Auto' and self.automaton and self.maneuver_set and windower.ffxi.get_ability_recasts()[210] == 0 then
		local pet_mode = self.automaton:get_pet_mode()
		local current_maneuvers = self:get_job():get_maneuvers()

		local maneuver_set = self.maneuver_set
		if buff_util.is_buff_active(buff_util.buff_id('Overdrive')) and self.overdriveManeuvers[pet_mode] then
			maneuver_set = self.overdriveManeuvers[pet_mode]
		end

		for maneuver in maneuver_set:it() do
			local maneuversActive = current_maneuvers:filter(function(maneuver_name) return maneuver_name == maneuver.Name end)
			if #maneuversActive < maneuver.Amount then
				self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, maneuver.Name), true)
				self.maneuver_last_used = os.time()
				return
			end
		end
	end
end

function PuppetmasterTrust:update_automaton(pet_id, pet_name)
	if self.automaton then
		self.automaton:destroy()
		self.automaton = nil
	end

	if pet_id then
		logger.notice(self.__class, 'pet change', pet_name, pet_id)

		self.automaton = Automaton.new(pet_id, self.action_queue)
		self.automaton:monitor()

		local pet_type = self.automaton:get_pet_mode()
		state.ManeuverMode:set(pet_type)
	end
end

function PuppetmasterTrust:shed_hate()
	if state.AutoEnmityReductionMode.value == 'Off' or self.target_index == nil or self.automaton == nil then return end

	local job_ability_names = job_util.get_enmity_reduction_job_abilities(player.main_job_name_short, player.sub_job_name_short):filter(function(job_ability_name)
		-- Don't use Ventriloquy if Provoke or Flashbulb recast are up just in case the automaton uses it
		-- before Ventriloquy goes off
		if job_ability_name == 'Ventriloquy' and (self.automaton:get_provoke_recast() < 5 or self.automaton:get_flash_recast() < 5) then
			return false
		else
			return true
		end
	end)
	for job_ability_name in job_ability_names:it() do
		local actions = L{
			WaitAction.new(0, 0, 0, 2),
			JobAbilityAction.new(0, 0, 0, job_ability_name, self.target_index)
		}
		self.action_queue:push_action(SequenceAction.new(actions, 'pup_hate_shed'), true)
		return
	end
end

return PuppetmasterTrust



