require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local BeastmasterTrust = setmetatable({}, {__index = Trust })
BeastmasterTrust.__index = BeastmasterTrust

function BeastmasterTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, nil, nil),
		Skillchainer.new(action_queue, L{'auto', 'prefer'})
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), BeastmasterTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function BeastmasterTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)

	self:check_pet()
end

function BeastmasterTrust:check_pet()
	if state.AutoPetMode.value == 'Off' then
		return
	end
	if not pet_util.has_pet() then
		self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Bestial Loyalty'), true)
	end
end

return BeastmasterTrust



