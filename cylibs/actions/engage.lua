--[[Copyright © 2019, Cyrite

Engage v1.0.0

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

require('actions')
require('vectors')
require('math')
require('logger')
require('lists')

local packets = require('packets')

local Skillchain = require('cylibs/battle/skillchain')

local Action = require('cylibs/actions/action')
local EngageAction = setmetatable({}, {__index = Action })
EngageAction.__index = EngageAction

function EngageAction.new(target_id, engage_distance, skillchain, approach)
	local self = setmetatable(Action.new(0, 0, 0), EngageAction)
	self.user_events = {}
	self.target_id = target_id
	self.engage_distance = engage_distance
	self.skillchain = skillchain
	self.approach = approach
	self.retry_count = 0
 	return self
end

function EngageAction:destroy()
	if self.user_events then
		for _,event in pairs(self.user_events) do
			windower.unregister_event(event)
		end
	end
	Action.destroy(self)
end

function EngageAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
	if not mob or mob.distance > self.engage_distance or mob.hpp <= 0 then
		return false
	end
	return true
end

function EngageAction:perform()
	self:kill_mob(self:gettargetid())
end

function EngageAction:complete(success)
	if self.skillchain then
		self.skillchain:disable()
	end
	
	windower.ffxi.follow()
	windower.ffxi.run(false)

	Action.complete(self, success)
end

function EngageAction:kill_mob(target_id)
	if self:is_cancelled() then
		return
	end

	local mob = windower.ffxi.get_mob_by_id(target_id)
	
	-- Mob is dead
	if not mob or mob.hpp <= 0 then
		self:complete(false)
		return
	end
	
	-- Mob is claimed
	if mob.claim_id ~= 0 then
		local claim_mob = windower.ffxi.get_mob_by_id(mob.claim_id) 
		if not claim_mob.in_party and claim_mob ~= windower.ffxi.get_player().id then
			self:complete(false)
			return
		end
	end

	if self.approach then
		self:follow_target(target_id)
	else
		self:attack_target(target_id)
	end
end

function EngageAction:follow_target(target_id)
	if self:is_cancelled() or self:is_completed() then
		self:complete(false)
		return
	end

	if self.retry_count > 5 then
		self:complete(false)
		return
	end

	local mob = windower.ffxi.get_mob_by_id(target_id)

	local player = windower.ffxi.get_player()
	if player.follow_index ~= mob.index then
		windower.ffxi.follow(mob.index)
		windower.ffxi.run()
	end

	if mob.distance < 6 then
		self:attack_target(target_id)
	else
		self.retry_count = self.retry_count + 1
		
		coroutine.sleep(2)
		
		self:follow_target(target_id)
	end
end

function EngageAction:attack_target(target_id)
	windower.ffxi.follow()
	windower.ffxi.run(false)

	local mob = windower.ffxi.get_mob_by_id(target_id)
	
	--windower.send_command('input /equipset 21')
	
	local p = packets.new('outgoing', 0x01A)

	p['Target'] = mob.id
	p['Target Index'] = mob.index
	p['Category'] = 0x02 -- Engage
	p['Param'] = 0
	p['X Offset'] = 0
	p['Z Offset'] = 0
	p['Y Offset'] = 0

	local attack_failure_message_ids = L{ 78, 198, 328, 71, 12, 16, 4, 154, 313 }

	self.user_events.incoming_chunk = windower.register_event('incoming chunk', function(id, data)
		if id == 0x29 then
			if self:is_cancelled() or self:is_completed() then
				windower.ffxi.follow()
				windower.ffxi.run(false)
				return
			end
		
			local p = packets.parse('incoming', data)

			local target_mob_id = p['Target']

			if target_id == target_mob_id then
				local message_id = p['Message']

				-- Player defeats the target
				if message_id == 6 or message_id == 20 then
					notice("Defeated monster")

					windower.ffxi.run(false)
					
					--coroutine.sleep(2)
					
					self:complete(true)

				-- Unable to see
				elseif message_id == 4 or message_id == 5 then
					if self.approach then
						windower.ffxi.follow(target_id)
						windower.ffxi.run()
					end
					
				-- Cannot attack monster
				elseif attack_failure_message_ids:contains(message_id) then
					notice("Cannot attack monster")
					self:complete(false)
				end
			end
		end
	end)
	
	if self.skillchain ~= nil then 
		notice("Enabling skillchain")
		self.skillchain:enable()
	end

	packets.inject(p)
end

function EngageAction:gettargetid()
	return self.target_id
end

function EngageAction:gettype()
	return "engageaction"
end

function EngageAction:getrawdata()
	local res = {}
	res.engageaction = {}
	return res
end

function EngageAction:tostring()
	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
    return "EngageAction: %s (%d)":format(mob.name, mob.id)
end

return EngageAction



