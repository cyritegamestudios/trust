require('tables')
require('lists')
require('logger')

BlueMage = require('cylibs/entity/jobs/BLU')

local Trust = require('cylibs/trust/trust')
local BlueMageTrust = setmetatable({}, {__index = Trust })
BlueMageTrust.__index = BlueMageTrust

local Buffer = require('cylibs/trust/roles/buffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local Puller = require('cylibs/trust/roles/puller')

function BlueMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local roles = S{
		Buffer.new(action_queue, S{}, trust_settings.SelfBuffs),
		Dispeler.new(action_queue, L{ Spell.new('Geist Wall'), Spell.new('Blank Gaze') }),
		Puller.new(action_queue, battle_settings.targets, 'Glutinous Dart', nil)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, BlueMage.new()), BlueMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function BlueMageTrust:on_init()
	Trust.on_init(self)

	self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
		local buffer = self:role_with_type("buffer")
		if buffer then
			buffer:set_job_abilities(new_trust_settings.JobAbilities)
			buffer:set_self_spells(new_trust_settings.SelfBuffs)
			buffer:set_party_spells(new_trust_settings.PartyBuffs)
		end
	end)
end

function BlueMageTrust:destroy()
	Trust.destroy(self)
end

function BlueMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index
end

function BlueMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return BlueMageTrust



