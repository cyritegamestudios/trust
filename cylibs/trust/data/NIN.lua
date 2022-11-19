require('tables')
require('lists')
require('logger')

Ninja = require('cylibs/entity/jobs/NIN')

local Trust = require('cylibs/trust/trust')
local NinjaTrust = setmetatable({}, {__index = Trust })
NinjaTrust.__index = NinjaTrust

function NinjaTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, S{}, trust_settings.SelfBuffs),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Ninja.new()), NinjaTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

return NinjaTrust



