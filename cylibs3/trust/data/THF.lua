require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local ThiefTrust = setmetatable({}, {__index = Trust })
ThiefTrust.__index = ThiefTrust

function ThiefTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), ThiefTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

return ThiefTrust



