local DisposeBag = require('cylibs/events/dispose_bag')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local Geocolure = require('cylibs/entity/geocolure')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Puller = require('cylibs/trust/roles/puller')
local zone_util = require('cylibs/util/zone_util')

Geomancer = require('cylibs/entity/jobs/GEO')

local Trust = require('cylibs/trust/trust')
local GeomancerTrust = setmetatable({}, {__index = Trust })
GeomancerTrust.__index = GeomancerTrust

state.AutoGeoMode = M{['description'] = 'Use geocolures', 'Off', 'Auto'}
state.AutoGeoMode:set_description('Auto', "Use Geocolure spells.")

state.AutoIndiMode = M{['description'] = 'Use indicolures', 'Auto', 'Off'}
state.AutoIndiMode:set_description('Auto', "Use Indicolure spells.")

state.AutoEntrustMode = M{['description'] = 'Use entrust', 'Auto', 'Off'}
state.AutoEntrustMode:set_description('Auto', "Entrust Indicolure spells on party members.")

function GeomancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Geomancer.new()
	local entrust = trust_settings.Geomancy.Entrust:copy()
	entrust.conditions = L{}
	local entrustGambit = Gambit.new(GambitTarget.TargetType.Ally, trust_settings.Geomancy.Entrust.conditions + L{ JobAbilityRecastReadyCondition.new('Entrust') }, entrust, "Ally")
	local roles = S{
		Buffer.new(action_queue, { Gambits = L{ entrustGambit } }, state.AutoEntrustMode, job),
		MagicBurster.new(action_queue, trust_settings.NukeSettings, 0.8, L{ 'Theurgic Focus' }, job),
		Nuker.new(action_queue, trust_settings.NukeSettings, 0.8, L{}, job),
		Puller.new(action_queue, trust_settings.PullSettings, job),
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), GeomancerTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.indi_spell = trust_settings.Geomancy.Indi
	self.geo_spell = trust_settings.Geomancy.Geo
	self.target_change_time = os.time()
	self.dispose_bag = DisposeBag.new()

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

	self.dispose_bag:add(self:get_player():on_pet_change():addAction(
			function (_, pet_id, pet_name)
				if L{'Luopan','luopan'}:contains(pet_name) then
					self:update_luopan(pet_id)
				end
			end), self:get_player():on_pet_change())

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		self.indi_spell = new_trust_settings.Geomancy.Indi
		self.geo_spell = new_trust_settings.Geomancy.Geo

		local buffer = self:role_with_type("buffer")

		local entrust = new_trust_settings.Geomancy.Entrust:copy()
		entrust.conditions = L{}

		local entrustGambit = Gambit.new(GambitTarget.TargetType.Ally, new_trust_settings.Geomancy.Entrust.conditions + L{ JobAbilityRecastReadyCondition.new('Entrust') }, entrust, "Ally")
		buffer:set_buff_settings({ Gambits = L{ entrustGambit } })

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)
end

function GeomancerTrust:destroy()
	Trust.destroy(self)

	if self.geocolure then
		self.geocolure:destroy()
	end
	self.dispose_bag:destroy()
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
	if state.AutoIndiMode.value == 'Off' then
		return
	end
	if not zone_util.is_city(windower.ffxi.get_info().zone) and not buff_util.is_buff_active(buff_util.buff_id('Colure Active')) then
		self.action_queue:push_action(SpellAction.new(0, 0, 0, self.indi_spell:get_spell().id, nil, self:get_player()), true)
	end
end

function GeomancerTrust:check_geo()
	if state.AutoGeoMode.value == 'Off' or zone_util.is_city(windower.ffxi.get_info().zone) then
		return
	end

	local delta_time = os.time() - self.target_change_time

	if self.geocolure and self.geocolure:is_alive() then
		if delta_time > 8 and not self.geocolure:is_in_range(self.geo_spell:get_target()) then
			self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Full Circle'), true)
		else
			self.geocolure:ecliptic_attrition()

			if self.geocolure:get_mob().hpp < 25 then
				self.geocolure:life_cycle()
			end
		end
	else
		if self.geo_spell and delta_time > 8 then
			local target = windower.ffxi.get_mob_by_target(self.geo_spell:get_target()) or windower.ffxi.get_mob_by_name(self.geo_spell:get_target())
			if target then
				local actions = L{}
				if player_util.get_job_ability_recast('Blaze of Glory') == 0 then
					actions:append(JobAbilityAction.new(0, 0, 0, 'Blaze of Glory'))
					actions:append(WaitAction.new(0, 0, 0, 1))
				end
				actions:append(SpellAction.new(0, 0, 0, self.geo_spell:get_spell().id, target.index, self:get_player()))
				actions:append(WaitAction.new(0, 0, 0, 2))

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



