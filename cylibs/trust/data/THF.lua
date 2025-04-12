local Trust = require('cylibs/trust/trust')
local ThiefTrust = setmetatable({}, {__index = Trust })
ThiefTrust.__index = ThiefTrust

local Dispeler = require('cylibs/trust/roles/dispeler')
local Puller = require('cylibs/trust/roles/puller')
local Thief = require('cylibs/entity/jobs/THF')

function ThiefTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Thief.new()
	local roles = S{
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Steal') }, false),
		Puller.new(action_queue, trust_settings.PullSettings, job)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), ThiefTrust)

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



