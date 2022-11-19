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

local Action = require('cylibs/actions/action')
local FollowAction = setmetatable({}, {__index = Action })
FollowAction.__index = FollowAction

function FollowAction.new(target_id)
	local self = setmetatable(Action.new(0, 0, 0), FollowAction)
	self.target_id = target_id
	self.retry_count = 0
 	return self
end

function FollowAction:can_perform()
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

function FollowAction:perform()
	self:follow_target(self:gettargetid())
end

function FollowAction:follow_target(target_id)
	if self:is_cancelled() or self:is_completed() then
		return
	end		

	local mob = windower.ffxi.get_mob_by_id(target_id)
	
	local player = windower.ffxi.get_player()
	if player.follow_index ~= mob.index then
		windower.ffxi.follow(mob.index)
		windower.ffxi.run()
	end
	
	self:complete(true)
end

function FollowAction:gettargetid()
	return self.target_id
end

function FollowAction:gettype()
	return "followaction"
end

function FollowAction:getrawdata()
	local res = {}
	res.followaction = {}
	return res
end

function FollowAction:tostring()
	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
    return "FollowAction: %s (%d)":format(mob.name, mob.id)
end

return FollowAction



