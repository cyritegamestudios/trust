local Trust = require('cylibs/trust/trust')
local ThiefTrust = setmetatable({}, {__index = Trust })
ThiefTrust.__index = ThiefTrust

local Approach = require('cylibs/battle/approach')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Puller = require('cylibs/trust/roles/puller')

function ThiefTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Dispeler.new(action_queue, L{}, L{ JobAbility.new('Steal') }, false),
		Puller.new(action_queue, battle_settings.targets, L{ Approach.new() })
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings), ThiefTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function ThiefTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local puller = self:role_with_type("puller")
		if puller then
			puller:set_pull_settings(new_trust_settings.PullSettings)
		end
	end)
end

function ThiefTrust:destroy()
	Trust.destroy(self)
end

return ThiefTrust



