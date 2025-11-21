local Bubbler = require('cylibs/trust/roles/bubbler')
local DisposeBag = require('cylibs/events/dispose_bag')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local Nuker = require('cylibs/trust/roles/nuker')
local Buffer = require('cylibs/trust/roles/buffer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local Puller = require('cylibs/trust/roles/puller')

Geomancer = require('cylibs/entity/jobs/GEO')

local Trust = require('cylibs/trust/trust')
local GeomancerTrust = setmetatable({}, {__index = Trust })
GeomancerTrust.__index = GeomancerTrust

state.AutoIndiMode = M{['description'] = 'Use indicolures', 'Auto', 'Off'}
state.AutoIndiMode:set_description('Auto', "Use Indicolure spells.")

state.AutoEntrustMode = M{['description'] = 'Use entrust', 'Auto', 'Off'}
state.AutoEntrustMode:set_description('Auto', "Entrust Indicolure spells on party members.")

function GeomancerTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Geomancer.new()

	local roles = S{
		Bubbler.new(action_queue, trust_settings.Geomancy, job),
		Buffer.new(action_queue, GeomancerTrust.get_buff_settings(trust_settings.Geomancy), state.AutoIndiMode, job),
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

	return self
end

function GeomancerTrust.get_buff_settings(geomancy_settings)
	return {
		Gambits = L{
			Gambit.new(GambitTarget.TargetType.Ally, L{
				GambitCondition.new(ModeCondition.new('AutoEntrustMode', 'Auto'), GambitTarget.TargetType.Self),
				GambitCondition.new(geomancy_settings.Entrust.conditions:firstWhere(function(c) return c.__type == JobCondition.__type end), GambitTarget.TargetType.Ally),
				GambitCondition.new(NotCondition.new(L{ InTownCondition.new() }), GambitTarget.TargetType.Self),
			}, Spell.new(geomancy_settings.Entrust:get_name(), L{ 'Entrust' }), GambitTarget.TargetType.Self),
			Gambit.new(GambitTarget.TargetType.Self, L{
				GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('Colure Active') }), GambitTarget.TargetType.Self),
				GambitCondition.new(NotCondition.new(L{ InTownCondition.new() }), GambitTarget.TargetType.Self),
			}, geomancy_settings.Indi, GambitTarget.TargetType.Self)
		}
	}
end

function GeomancerTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		buffer:set_buff_settings(GeomancerTrust.get_buff_settings(new_trust_settings.Geomancy))

		local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
		for role in nuker_roles:it() do
			role:set_nuke_settings(new_trust_settings.NukeSettings)
		end
	end)
end

function GeomancerTrust:destroy()
	Trust.destroy(self)

	self.dispose_bag:destroy()
end

return GeomancerTrust



