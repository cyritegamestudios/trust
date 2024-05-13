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
		return V{0, 0, 0}
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

--- Gets a list of all mobs within 25y that are valid, within a certain Z distance, unclaimed, and not excluded
-- @param target_mobs (optional) A list of mob names, if empty will get all mobs
-- @param exclude_target_indices (optional) A list of indexes to exclude, commonly used to exclude party targets
-- @param exclude_names (optional) A list of mob names to exclude
-- @return A sorted list of mobs by distance
function ffxi_util.find_closest_mobs(target_mobs, exclude_target_indices, exclude_names)
	local player_mob = windower.ffxi.get_mob_by_target('me')
	local mob_array = windower.ffxi.get_mob_array()
	local mob_list = L{}
	-- TODO(Aldros): Is there a more efficient way, maybe rekeying the mob_array table
	for _, v in pairs(mob_array) do
		mob_list:append(v)
	end

	local closest_mobs = mob_list:filter(function(t)
		return t.valid_target -- Valid target
		    and t.hpp > 0
			and t.spawn_type == 16 -- mob
			and t.distance:sqrt() + player_mob.model_size + t.model_size < 20 -- Distance
			and (t.claim_id == 0 or t.claim_id == player_mob.id or party_util.party_claimed(t.id)) -- Unclaimed or party claimed
			and not (exclude_target_indices and exclude_target_indices:contains(t.index)) -- not in exclude indicies
			and not (exclude_names and exclude_names:contains(t.name)) -- not in exclude names
			and not (math.abs(player_mob.z - t.z) > 8) -- Z check from find_closest_mob
	end):filter(function(t) -- Handling for explicit filtering for name
		if target_mobs and target_mobs:length() > 0 then
			return target_mobs:contains(t.name)
		else
			return true
		end
	end):sort(function(t1, t2)
		return t1.distance < t2.distance
	end)

	return closest_mobs
end

-- Get all unclaimed engaged mobs from a list
function ffxi_util.get_engaged_unclaimed_mobs(mob_list)
	return mob_list:filter(function(t)
		return t and t.status == 1 and t.claim_id == 0
	end)
end

function ffxi_util.find_closest_mob(target_mobs, exclude_target_indices, exclude_names)
	return ffxi_util.find_closest_mobs(target_mobs, exclude_target_indices, exclude_names)[1]
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

function ffxi_util.mob_for_index(index)
	if index == nil then
		return nil
	end
	local mob = windower.ffxi.get_mob_by_index(index)
	if mob then
		return mob
	end
	return nil
end

return ffxi_util


