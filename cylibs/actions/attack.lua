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
require('math')
require('logger')
require('lists')

local packets = require('packets')

local Action = require('cylibs/actions/action')
local AttackAction = setmetatable({}, {__index = Action })
AttackAction.__index = AttackAction

function AttackAction.new(target_id)
	local self = setmetatable(Action.new(0, 0, 0), AttackAction)
	self.target_id = target_id
	self.user_events = {}
 	return self
end

function AttackAction:destroy()
	if self.user_events then
		for _,event in pairs(self.user_events) do
			windower.unregister_event(event)
		end
	end
	Action.destroy(self)
end

function AttackAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
	if not mob or mob.hpp <= 0 or not mob.valid_target then
		return false
	end
	if mob.claim_id ~= 0 then
		local claimed_by = windower.ffxi.get_mob_by_id(mob.claim_id)
		if claimed_by ~= nil and not (claimed_by.in_party or claimed_by.in_alliance) then
			return false
		end
	end
	return true
end

function AttackAction:perform()
	self:attack_target(self:gettargetid())
end

function AttackAction:attack_target(target_id)
	local mob = windower.ffxi.get_mob_by_id(target_id)
	
	local p = packets.new('outgoing', 0x01A)

	p['Target'] = mob.id
	p['Target Index'] = mob.index
	p['Category'] = 0x02 -- Engage
	p['Param'] = 0
	p['X Offset'] = 0
	p['Z Offset'] = 0
	p['Y Offset'] = 0

	local attack_failure_message_ids = L{ 78, 198, 328, 71, 12, 16, 4, 154, 313 }

	self.user_events.incoming = windower.register_event('incoming chunk', function(id, data)
		if id == 0x29 then
			if self:is_cancelled() then
				windower.ffxi.follow()
				windower.ffxi.run(false)
				return
			end
		
			local p = packets.parse('incoming', data)

			local target_mob_id = p['Target']

			if target_id == target_mob_id then
				local message_id = p['Message']

				if attack_failure_message_ids:contains(message_id) then
					self:complete(false)
				end
			end
		end
	end)
	
	self.user_events.status_change = windower.register_event('status change',
		function(new_status_id, old_status_id)
			-- Engaged
			if new_status_id == 1 then
				self:complete(true)
			end
		end
	)
	
	packets.inject(p)
end

function AttackAction:gettargetid()
	return self.target_id
end

function AttackAction:gettype()
	return "attackaction"
end

function AttackAction:getrawdata()
	local res = {}
	res.attackaction = {}
	return res
end

function AttackAction:tostring()
	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
    return "AttackAction: %s (%d)":format(mob.name, mob.id)
end

return AttackAction



