require('tables')
require('lists')
require('logger')

Geomancer = require('cylibs/entity/jobs/GEO')

local Trust = require('cylibs/trust/trust')
local GeomancerTrust = setmetatable({}, {__index = Trust })
GeomancerTrust.__index = GeomancerTrust

local Geocolure = require('cylibs/entity/geocolure')

local Dispeler = require('cylibs/trust/roles/dispeler')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')

state.AutoGeoMode = M{['description'] = 'Auto Geo Mode', 'Off', 'Auto'}

function GeomancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Geomancer.new()
	local roles = S{
		Buffer.new(action_queue, S{}, trust_settings.SelfBuffs, trust_settings.PartyBuffs),
		Dispeler.new(action_queue),
		Nuker.new(action_queue),
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), GeomancerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.indi_spell = trust_settings.Geomancy.Indi
	self.geo_spell = trust_settings.Geomancy.Geo
	self.target_change_time = os.time()

	if pet_util.has_pet() then
		self:update_luopan(pet_util.get_pet().id)
	end

	return self
end

function GeomancerTrust:on_init()
	Trust.on_init(self)

	if pet_util.has_pet() then
		self:update_luopan(pet_util.get_pet().id)
	end

	self.pet_changed_action_id = self:get_player():on_pet_change():addAction(
			function (_, pet_id, pet_name)
				if L{'Luopan','luopan'}:contains(pet_name) then
					self:update_luopan(pet_id)
				end
			end)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)
		buffer:set_party_spells(new_trust_settings.PartyBuffs)

		self.indi_spell = new_trust_settings.Geomancy.Indi
		self.geo_spell = new_trust_settings.Geomancy.Geo
	end)
end

function GeomancerTrust:destroy()
	Trust.destroy(self)

	self:get_player():on_pet_change():removeAction(self.pet_changed_action_id)
end

function GeomancerTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
	self.target_change_time = os.time()
end

function GeomancerTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_indi()
	self:check_geo()
end

function GeomancerTrust:check_indi()
	if not buff_util.is_buff_active(buff_util.buff_id('Colure Active')) then
		self.action_queue:push_action(SpellAction.new(0, 0, 0, self.indi_spell:get_spell().id, nil, self:get_player()), true)
	end
end

function GeomancerTrust:check_geo()
	if state.AutoGeoMode.value == 'Off' then
		return
	end

	local delta_time = os.time() - self.target_change_time

	if self.geocolure and self.geocolure:is_alive() then
		if delta_time > 8 and not self.geocolure:is_in_range(self.geo_spell:get_target()) then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Full Circle'), true)
		else
			self.geocolure:ecliptic_attrition()
		end
	else
		if self.geo_spell and delta_time > 8 then
			local target = windower.ffxi.get_mob_by_target(self.geo_spell:get_target())
			if target then
				local actions = L{}
				if player_util.get_job_ability_recast('Blaze of Glory') == 0 then
					actions:append(JobAbilityAction.new(0, 0, 0, 'Blaze of Glory'))
					actions:append(WaitAction.new(0, 0, 0, 1))
				end
				actions:append(SpellAction.new(0, 0, 0, self.geo_spell:get_spell().id, target.index, self:get_player()))
				actions:append(WaitAction.new(0, 0, 0, 1))

				self.action_queue:push_action(SequenceAction.new(actions, self.geo_spell:get_spell().id), true)
			end
		end
	end
end

function GeomancerTrust:update_luopan(pet_id)
	if self.geocolure then
		self.geocolure:destroy()
		self.geocolure = nil
	end

	if pet_id then
		self.geocolure = Geocolure.new(pet_id, self.action_queue)
		self.geocolure:monitor()
	end
end

return GeomancerTrust



