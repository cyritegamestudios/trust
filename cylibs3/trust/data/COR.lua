require('tables')
require('lists')
require('logger')

Corsair = require('cylibs/entity/jobs/COR')

local Trust = require('cylibs/trust/trust')
local CorsairTrust = setmetatable({}, {__index = Trust })
CorsairTrust.__index = CorsairTrust

local Roller = require('cylibs/trust/roles/roller')

function CorsairTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Corsair.new(action_queue)
	local roles = S{
		Buffer.new(action_queue, S{}, S{}),
		Dispeler.new(action_queue),
		Shooter.new(action_queue),
		Roller.new(action_queue, job, trust_settings.Roll1, trust_settings.Roll2),
		Skillchainer.new(action_queue, L{'auto', 'prefer'})
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), CorsairTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function CorsairTrust:on_init()
	Trust.on_init(self)
end

function CorsairTrust:destroy()
	Trust.destroy(self)

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
	end
end

return CorsairTrust



