require('tables')
require('lists')
require('logger')

Corsair = require('cylibs/entity/jobs/COR')

local Trust = require('cylibs/trust/trust')
local CorsairTrust = setmetatable({}, {__index = Trust })
CorsairTrust.__index = CorsairTrust

local CorsairModes = require('cylibs/trust/data/modes/COR')
local Dispeler = require('cylibs/trust/roles/dispeler')
local DisposeBag = require('cylibs/events/dispose_bag')
local ModeDelta = require('cylibs/modes/mode_delta')
local Puller = require('cylibs/trust/roles/puller')
local Roller = require('cylibs/trust/roles/roller')
local Shooter = require('cylibs/trust/roles/shooter')

function CorsairTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Corsair.new(action_queue)
	local roles = S{
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Dark Shot') }, false),
		Shooter.new(action_queue),
		Roller.new(action_queue, job, trust_settings.Roll1, trust_settings.Roll2),
		Puller.new(action_queue, battle_settings.targets, nil, nil, true)
	}

	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), CorsairTrust)

	self.settings = settings
	self.action_queue = action_queue
	self.roll_modes_delta = ModeDelta.new(CorsairModes.Rolling)
	self.dispose_bag = DisposeBag.new()

	return self
end

function CorsairTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local roller = self:role_with_type("roller")

		roller:set_rolls(new_trust_settings.Roll1, new_trust_settings.Roll2)
	end)

	local roller = self:role_with_type("roller")

	self.dispose_bag:add(roller:on_rolls_begin():addAction(function(_)
		self:get_party():add_to_chat(self.party:get_player(), "Doing rolls, hold tight.", "on_rolls_begin", 5)
		self.roll_modes_delta:apply()
	end), roller:on_rolls_begin())

	self.dispose_bag:add(roller:on_rolls_end():addAction(function(_)
		self:get_party():add_to_chat(self.party:get_player(), "Alright, you're good to go for now!", "on_rolls_end", 5)
		self.roll_modes_delta:remove()
	end), roller:on_rolls_end())
end

function CorsairTrust:destroy()
	Trust.destroy(self)

	self.dispose_bag:destroy()

	if self.battle_target then
		self.battle_target:destroy()
		self.battle_target = nil
	end
end

function CorsairTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	if self.battle_target then
		self.battle_target:destroy()
		self.battle_target = nil
	end

	self.target_index = target_index

	if target_index then
		self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
		self.battle_target:monitor()
		self.battle_target:on_gain_debuff():addAction(
				function (_, debuff_name)
					self:quick_draw(debuff_name)
				end)
	end
end

function CorsairTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

function CorsairTrust:quick_draw(debuff_name)
	if L{'Dia'}:contains(debuff_name) then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Light Shot', self.target_index))
	elseif L{'Silence'}:contains(debuff_name) then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Wind Shot', self.target_index))
	elseif L{'slow'}:contains(debuff_name) then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Earth Shot', self.target_index))
	elseif L{'Bio','blindness'}:contains(debuff_name) then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Dark Shot', self.target_index))
	elseif L{'poison'}:contains(debuff_name) then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Water Shot', self.target_index))
	elseif L{'paralysis'}:contains(debuff_name) then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Ice Shot', self.target_index))
	end
end

return CorsairTrust



