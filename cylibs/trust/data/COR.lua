Corsair = require('cylibs/entity/jobs/COR')

local Trust = require('cylibs/trust/trust')
local CorsairTrust = setmetatable({}, {__index = Trust })
CorsairTrust.__index = CorsairTrust

local CorsairModes = require('cylibs/trust/data/modes/COR')
local Dispeler = require('cylibs/trust/roles/dispeler')
local DisposeBag = require('cylibs/events/dispose_bag')
local ModeDelta = require('cylibs/modes/mode_delta')
local Puller = require('cylibs/trust/roles/puller')
local RangedAttack = require('cylibs/battle/ranged_attack')
local Roller = require('cylibs/trust/roles/roller')
local Shooter = require('cylibs/trust/roles/shooter')

function CorsairTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Corsair.new(action_queue, state.AutoRollMode)
	local roles = S{
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Dark Shot') }, false),
		Shooter.new(action_queue, trust_settings.Shooter.Delay or 1.5),
		Roller.new(action_queue, job, trust_settings.Roll1, trust_settings.Roll2),
		Puller.new(action_queue, battle_settings.targets, L{ RangedAttack.new() })
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), CorsairTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.roll_modes_delta = ModeDelta.new(CorsairModes.Rolling, "You cannot change modes while rolling.", S{ 'AutoRollMode' })
	self.dispose_bag = DisposeBag.new()

	return self
end

function CorsairTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local roller = self:role_with_type("roller")
		roller:set_rolls(new_trust_settings.Roll1, new_trust_settings.Roll2)

		local shooter = self:role_with_type("shooter")
		shooter:set_shoot_delay(new_trust_settings.Shooter.Delay)

		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)

	local roller = self:role_with_type("roller")

	self.dispose_bag:add(roller:on_rolls_begin():addAction(function(_)
		self:get_party():add_to_chat(self.party:get_player(), "Doing rolls, hold tight.", "on_rolls_begin")
		self.roll_modes_delta:apply()
	end), roller:on_rolls_begin())

	self.dispose_bag:add(roller:on_rolls_end():addAction(function(_)
		self:get_party():add_to_chat(self.party:get_player(), "Alright, you're good to go for now!", "on_rolls_end")
		self.roll_modes_delta:remove()
	end), roller:on_rolls_end())
end

function CorsairTrust:destroy()
	Trust.destroy(self)

	self.dispose_bag:destroy()
end

function CorsairTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)
end

function CorsairTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return CorsairTrust



