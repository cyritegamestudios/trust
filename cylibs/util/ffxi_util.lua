--[[Copyright © 2019, Cyrite

Farm v1.0.0

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

_libs = _libs or {}

require('logger')
require('tables')
require('vectors')

local math = require('math')

local ffxi_util = {}

_raw = _raw or {}

_libs.ffxi_util = ffxi_util

function ffxi_util.distance(v1, v2)
	if not v1 or not v2 then
		return 0
	end

	return math.sqrt((v1[1]-v2[1])^2+(v1[2]-v2[2])^2+(v1[3]-v2[3])^2)
end

function ffxi_util.get_player_position()
	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

	local v = vector.zero(3)

	v[1] = player.x
	v[2] = player.y
	v[3] = player.z

	return v
end

function ffxi_util.get_mob_position(mob_name)
	local mob = windower.ffxi.get_mob_by_name(mob_name)
	if not mob then
		return nil
	end

	local v = vector.zero(3)

	v[1] = mob.x
	v[2] = mob.y
	v[3] = mob.z

	return v
end

function ffxi_util.get_direction_to_point(p)
	local x = p[1]+math.random()*0.01 - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).x
	local y = p[2]+math.random()*0.01 - windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).y
	local h = math.atan2(x, y)

	local direction = h - 1.5708
	return direction
end

function ffxi_util.find_closest_mob(target_mobs, exclude_target_indices)
	local player = windower.ffxi.get_player()
	local player_mob = windower.ffxi.get_mob_by_id(player.id)
	local closest_mob = nil

	local mob_array = windower.ffxi.get_mob_array()
    for i, mob in pairs(mob_array) do
    	local deltaZ = math.abs(player_mob.z - mob.z)
    	
		-- Check to see if mob is in target_mob list
		local is_target_mob = false
		for i, target_mob in pairs(target_mobs) do
			if string.match(mob.name, target_mob) then
				is_target_mob = true
			end
		end

		if target_mobs:empty() then
			is_target_mob = true
		end
		if exclude_target_indices == nil then
			exclude_target_indices = L{}
		end
		
    	if mob.id ~= player.id and not exclude_target_indices:contains(mob.index) and deltaZ < 2 and is_target_mob and mob.hpp > 0 and (mob.claim_id == 0 or mob.claim_id == player.id or party_util.party_claimed(mob.id)) and mob.valid_target and mob.spawn_type == 16 and (closest_mob == nil or mob.distance < closest_mob.distance) then
			closest_mob = mob
        end
    end

    return closest_mob
end

function ffxi_util.mob_id_for_index(index)
	if index == nil then
		return nil
	end
	local mob = windower.ffxi.get_mob_by_index(index)
	if mob then
		return mob.id
	end
	return nil
end

return ffxi_util


