Warrior = require('cylibs/entity/jobs/WAR')

local Trust = require('cylibs/trust/trust')
local WarriorTrust = setmetatable({}, {__index = Trust })
WarriorTrust.__index = WarriorTrust

local Puller = require('cylibs/trust/roles/puller')
local Buffer = require('cylibs/trust/roles/buffer')
local Tank = require('cylibs/trust/roles/tank')

function WarriorTrust.new(settings, action_queue, battle_settings, trust_settings)
	local job = Warrior.new()
	local roles = S{
		Puller.new(action_queue, trust_settings.PullSettings),
		Tank.new(action_queue, L{ 'Provoke' }, L{}),
		Buffer.new(action_queue, trust_settings.BuffSettings, state.AutoBuffMode.value, job),
	}
	local self = setmetatable(Trust.new(action_queue, roles, trust_settings, job), WarriorTrust)
	return self
end

return WarriorTrust



