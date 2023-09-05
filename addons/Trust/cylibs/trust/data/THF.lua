require('tables')
require('lists')
require('logger')

local Trust = require('cylibs/trust/trust')
local ThiefTrust = setmetatable({}, {__index = Trust })
ThiefTrust.__index = ThiefTrust

local Dispeler = require('cylibs/trust/roles/dispeler')

function ThiefTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Dispeler.new(action_queue, L{}, L{ 'Steal '})
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), ThiefTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function ThiefTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
	end)
end

function ThiefTrust:destroy()
	Trust.destroy(self)
end

return ThiefTrust



