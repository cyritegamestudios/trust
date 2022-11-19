--[[Copyright © 2019, Cyrite

Path v1.0.0

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

require('vectors')
require('math')
require('logger')

local PlayerUtil = require('cylibs/util/player_util')

local Action = require('cylibs/actions/action')
local WalkAction = setmetatable({}, {__index = Action })
WalkAction.__index = WalkAction

function WalkAction.new(x, y, z)
	local self = setmetatable(Action.new(x, y, z), WalkAction)
 	return self
end

function WalkAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	local player = windower.ffxi.get_player()
	if player.status == 44 then
		return false
	end

	local dist = PlayerUtil.distance(PlayerUtil.get_player_position(), self:get_position())

	if dist < 3 or dist > 500 then
		return false
	end
	
	return true
end

function WalkAction:perform()
	self:walk_to_point(self:get_position(), 0)
end

function WalkAction:walk_to_point(v, retry_count)
	if self:is_cancelled() then
		return
	end
	
	windower.ffxi.follow()

	if retry_count > 20 then
		self:complete(false)
		return
	end

	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

	local p = vector.zero(3)

	p[1] = player.x
	p[2] = player.y
	p[3] = player.z

	local dist = math.sqrt((p[1]-v[1])^2+(p[2]-v[2])^2+(p[3]-v[3])^2)

	if dist < 2 then
		windower.ffxi.run(false) 
		self:complete(true)
	else
		if self:is_cancelled() then
			windower.ffxi.run(false)
			return
		end
		
		local x = v[1]+math.random()*0.01 - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).x
		local y = v[2]+math.random()*0.01 - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).y
		local h = math.atan2(x, y)

		local direction = h - 1.5708

		windower.ffxi.run(direction)

		local walk_speed = 10
		local walk_time = dist / walk_speed

		coroutine.schedule(function()
			self:walk_to_point(v, retry_count + 1)
		end, walk_time)
	end
end

function WalkAction:distance(x, y, z)
	return math.sqrt((self.x-x)^2+(self.y-y)^2+(self.z-z)^2)
end

function WalkAction:gettype()
	return "walkaction"
end

function WalkAction:getrawdata()
	local res = {}
	
	res.walkaction = {}
	res.walkaction.x = self.x
	res.walkaction.y = self.y
	res.walkaction.z = self.z
	
	return res
end

function WalkAction:copy()
	return WalkAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function WalkAction:tostring()
    return "WalkAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return WalkAction



