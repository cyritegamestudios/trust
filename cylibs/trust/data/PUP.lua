Puppetmaster = require('cylibs/entity/jobs/PUP')

local DisposeBag = require('cylibs/events/dispose_bag')
local Frame = require('cylibs/ui/views/frame')
local JobAbilityAction = require('cylibs/actions/job_ability')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local party_util = require('cylibs/util/party_util')
local pet_util = require('cylibs/util/pet_util')

local Trust = require('cylibs/trust/trust')
local PuppetmasterTrust = setmetatable({}, {__index = Trust })
PuppetmasterTrust.__index = PuppetmasterTrust
PuppetmasterTrust.__class = "PuppetmasterTrust"

Automaton = require('cylibs/entity/automaton')

local Dispeler = require('cylibs/trust/roles/dispeler')
local Buffer = require('cylibs/trust/roles/buffer')
local Puller = require('cylibs/trust/roles/puller')

state.AutoAssaultMode = M{['description'] = 'Deploy Pet in Battle', 'Off', 'Auto'}
state.AutoAssaultMode:set_description('Auto', "Okay, my pet will fight with me!")

state.AutoManeuverMode = M{['description'] = 'Use Maneuvers', 'Off', 'Auto'}
state.AutoManeuverMode:set_description('Auto', "Okay, I'll automatically use maneuvers.")

state.AutoPetMode = M{['description'] = 'Call Pet', 'Off', 'Auto'}
state.AutoPetMode:set_description('Auto', "Okay, I'll automatically call a pet.")

state.AutoRepairMode = M{['description'] = 'Use Repair', 'Auto', 'Off'}
state.AutoRepairMode:set_description('Auto', "Okay, I'll use repair when my automaton's HP is low.")

function PuppetmasterTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.BuffSettings),
		Puller.new(action_queue, trust_settings.PullSettings),
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Dark Maneuver', L{ HasAttachmentsCondition.new(L{ 'regulator', 'disruptor' }), NotCondition.new(L{ HasBuffCondition.new('Dark Maneuver', windower.ffxi.get_player().index) }, windower.ffxi.get_player().index) }, L{}, 'me') }, false),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Puppetmaster.new()), PuppetmasterTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.maneuver_last_used = os.time()
	self.economizer_last_used = os.time()
	self.target_change_time = os.time()
	self.dispose_bag = DisposeBag.new()

	local mode_names = T(T(trust_settings.AutomatonSettings.ManeuverSettings.Default):keyset()):map(function(m)
		return m
	end)
	state.ManeuverMode = M{['description'] = 'Maneuver Set', mode_names}
	for mode_name in mode_names:it() do
		state.ManeuverMode:set_description(mode_name, 'Maneuver set for '..mode_name..' pet type.')
	end

	return self
end

function PuppetmasterTrust:on_init()
	Trust.on_init(self)

	if pet_util.has_pet() then
		self:update_automaton(pet_util.get_pet().id, pet_util.get_pet().name)
	end

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self:get_job():set_maneuver_settings(new_trust_settings.AutomatonSettings.ManeuverSettings)
	end)

	self.dispose_bag:add(self:get_player():on_pet_change():addAction(
		function (_, pet_id, pet_name)
			self:update_automaton(pet_id, pet_name)
		end), self:get_player():on_pet_change())
end

function PuppetmasterTrust:on_deinit()
	self:update_automaton(nil, nil)

	state.ManeuverMode:on_state_change():removeAllActions()

	self.dispose_bag:destroy()
end

function PuppetmasterTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

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

function PuppetmasterTrust:check_maneuvers()
	if os.time() - self.maneuver_last_used < 5 then
		return
	end

	if state.AutoManeuverMode.value == 'Auto' and self.automaton and windower.ffxi.get_ability_recasts()[210] == 0 then
		local maneuver_set = self:get_job():get_maneuvers(state.ManeuverMode.value)

		for element in L{ 'Fire', 'Earth', 'Water', 'Wind', 'Ice', 'Thunder', 'Light', 'Dark' }:it() do
			local num_required = maneuver_set:getNumManeuvers(element)
			if not Condition.check_conditions(L{ HasBuffsCondition.new(L{ element..' Maneuver' }, num_required) }, windower.ffxi.get_player().index) then
				local maneuver_action = JobAbilityAction.new(0, 0, 0, element..' Maneuver')
				maneuver_action.identifier = 'use_maneuver'
				self.action_queue:push_action(maneuver_action, true)
				self.maneuver_last_used = os.time()
				return
			end
		end
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
	if not self.automaton then
		return
	end

	local pet_type = self.automaton:get_pet_mode()
	state.ManeuverMode:set(pet_type)

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

function PuppetmasterTrust:set_maneuver_settings(maneuver_settings)
	self.maneuver_settings = maneuver_settings
end

function PuppetmasterTrust:get_widget()
	local AutomatonStatusWidget = require('ui/widgets/AutomatonStatusWidget')
	local petStatusWidget = AutomatonStatusWidget.new(
			Frame.new(0, 0, 125, 57),
			windower.trust.settings.get_addon_settings(),
			self:get_party():get_player(),
			windower.trust.ui.get_hud(),
			windower.trust.settings.get_job_settings('PUP'),
			state.MainTrustSettingsMode,
			windower.trust.settings.get_mode_settings()
	)
	return petStatusWidget, "pet"
end

return PuppetmasterTrust



