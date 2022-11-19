--[[Copyright © 2019, Cyrite

Path v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

require('tables')
require('lists')
require('logger')

Puppetmaster = require('cylibs/entity/jobs/PUP')

local Trust = require('cylibs/trust/trust')
local PuppetmasterTrust = setmetatable({}, {__index = Trust })
PuppetmasterTrust.__index = PuppetmasterTrust

Automaton = require('cylibs/entity/automaton')

state.AutoManeuverMode = M{['description'] = 'Auto Maneuver Mode', 'Off', 'Auto'}
state.AutoRepairMode = M{['description'] = 'Auto Repair Mode', 'Auto', 'Off'}

function PuppetmasterTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, S{}, S{}),
		Dispeler.new(action_queue),
		Skillchainer.new(action_queue, L{'auto', 'prefer', 'am'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Puppetmaster.new()), PuppetmasterTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.defaultManeuvers = trust_settings.DefaultManeuvers
	self.overdriveManeuvers = trust_settings.OverdriveManeuvers
	self.automaton_name = trust_settings.AutomatonName
	self.maneuver_last_used = os.time()

	return self
end

function PuppetmasterTrust:destroy()
	Trust.destroy(self)

	self:update_automaton(nil, nil)

	self:get_player():on_pet_change():removeAction(self.pet_changed_action_id)
end

function PuppetmasterTrust:on_init()
	Trust.on_init(self)

	if pet_util.has_pet() then
		self:update_automaton(pet_util.get_pet().id, pet_util.get_pet().name)
	end

	self.pet_changed_action_id = self:get_player():on_pet_change():addAction(
			function (_, pet_id, pet_name)
				self:update_automaton(pet_id, pet_name)
			end)
end

function PuppetmasterTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
	self.target_change_time = os.time()
end

function PuppetmasterTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_automaton()

	if self.automaton then
		self:check_repair()
		self:check_overload()
		self:check_maneuvers()

		if state.AutoAssaultMode.value ~= 'Off' and self.automaton:is_idle() and self.target_index
				and windower.ffxi.get_mob_by_index(self.target_index) then
			local deploy_action = JobAbilityAction.new(0, 0, 0, 'Deploy', self.target_index)
			deploy_action.priority = ActionPriority.highest
			self.action_queue:push_action(deploy_action, true)
		end
	end
end

function PuppetmasterTrust:check_automaton()
	if self.automaton == nil then
		if state.AutoPetMode.value == 'Auto' then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Activate'), true)
		end
	else
		if self.automaton:is_mage() then
			local vitals = self.automaton:get_vitals()
			if vitals.hpp > 80 and vitals.mpp < 10 and job_util.can_use_job_ability('Deactivate') then
				self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Deactivate'), true)
			end
		end
	end
end

function PuppetmasterTrust:check_repair()
	if state.AutoRepairMode.value ~= 'Off' and self.automaton:get_mob().hpp < 20 and self:get_job():can_repair() then
		self.automaton:repair()
	end
end

function PuppetmasterTrust:check_overload()
	if self:get_job():is_overloaded() then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Cooldown'), true)
	end
end

function PuppetmasterTrust:check_maneuvers()
	if os.time() - self.maneuver_last_used < 5 then
		return
	end

	if state.AutoManeuverMode.value == 'Auto' and self.automaton and windower.ffxi.get_ability_recasts()[210] == 0 then
		local pet_mode = self.automaton:get_pet_mode()
		local current_maneuvers = self:get_job():get_maneuvers()

		local maneuver_set = self.defaultManeuvers[pet_mode]
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

	if pet_id and L{self.automaton_name}:contains(pet_name) then
		self.automaton = Automaton.new(pet_id, self.action_queue)
		self.automaton:monitor()
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



