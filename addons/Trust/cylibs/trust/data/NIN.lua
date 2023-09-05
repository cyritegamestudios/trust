require('tables')
require('lists')
require('logger')

Ninja = require('cylibs/entity/jobs/NIN')

local Trust = require('cylibs/trust/trust')
local NinjaTrust = setmetatable({}, {__index = Trust })
NinjaTrust.__index = NinjaTrust

local Buffer = require('cylibs/trust/roles/buffer')

function NinjaTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, trust_settings.JobAbilities, trust_settings.SelfBuffs),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, Ninja.new()), NinjaTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function NinjaTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")

		buffer:set_job_ability_names(new_trust_settings.JobAbilities)
		buffer:set_self_spells(new_trust_settings.SelfBuffs)
	end)
end

function NinjaTrust:destroy()
	Trust.destroy(self)
end

return NinjaTrust



