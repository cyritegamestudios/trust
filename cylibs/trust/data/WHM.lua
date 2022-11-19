require('tables')
require('lists')
require('logger')

WhiteMage = require('cylibs/entity/jobs/WHM')

local Trust = require('cylibs/trust/trust')
local WhiteMageTrust = setmetatable({}, {__index = Trust })
WhiteMageTrust.__index = WhiteMageTrust

local Raiser = require('cylibs/trust/roles/raiser')

function WhiteMageTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = WhiteMage.new(trust_settings.CureSettings)
	local roles = S{
		Buffer.new(action_queue, S{'Afflatus Solace'}, trust_settings.SelfBuffs, trust_settings.PartyBuffs),
		Debuffer.new(action_queue),
		Nuker.new(action_queue, 10),
		Healer.new(action_queue, job),
		Raiser.new(action_queue, job),
		Skillchainer.new(action_queue, L{'auto', 'prefer'}),
		--Evader.new(settings, action_queue)
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), WhiteMageTrust)

	self.settings = settings
	self.action_queue = action_queue

	return self
end

function WhiteMageTrust:job_target_change(target_index)
	Trust.job_target_change(self, target_index)

	self.target_index = target_index

	if self.target_index then
		--self.action_queue:push_action(SpellAction.new(0, 0, 0, res.spells:with('name', 'Dia II').id, self.target_index), true)
	end
end

function WhiteMageTrust:tic(old_time, new_time)
	Trust.tic(self, old_time, new_time)
end

return WhiteMageTrust