---------------------------
-- Utility functions for distance and geometry.
-- @class module
-- @name GeometryUtil

_libs = _libs or {}

require('tables')
require('vectors')

local math = require('math')

local geometry_util = {}

_raw = _raw or {}

_libs.geometry_util = geometry_util

-------
-- Converts an (x,y) coordinate to a vector.
-- @tparam number x X coordinate
-- @tparam number y Y coordinate
-- @treturn Vector The (x,y) coordinate as a Vector.
function geometry_util.point_to_vector(x, y)
	local v = vector.zero(3)
	v[1] = x
	v[2] = y
	return v
end

-------
-- Returns the distance between two mobs.
-- @tparam MobMetadata mob1 First mob
-- @tparam MobMetadata mob2 Second mob
-- @treturn number Distance in yalms
function geometry_util.distance(mob1, mob2)
	return ffxi_util.distance(geometry_util.point_to_vector(mob1.x, mob1.y), geometry_util.point_to_vector(mob2.x, mob2.y))
end

-------
-- Gets a vector behind the target mob. Useful if you want to position the playe behind a mob.
-- @tparam MobMetadata target Target mob
-- @treturn Vector A vector 5 yalms behind the target mob.
function geometry_util.get_point_behind_mob(target)
	local v = vector.zero(3)

	if not target or target.hpp <= 0 then return v end

	local direction = vector.zero(3)

	direction[1] = math.cos(target.facing)
	direction[2] = math.sin(target.facing)

	local origin = geometry_util.point_to_vector(target.x, target.y)

	v[1] = origin[1] + direction[1] * 5
	v[2] = origin[2] + direction[2] * 5
	v[3] = target.z

	return v
end

-------
-- The direction that the given target is facing, in radians. 0 is east, pi/2 south, -pi or pi is west, -pi/2 is north.
-- @tparam MobMetadata target Target mob
-- @treturn number Direction of the target in radians.
function geometry_util.target_direction(target)
	local dir = target.facing
	if dir < 0 then
		dir = -dir
	else
		dir = 2 * math.pi - dir
	end
	return dir
end

-------
-- Determines if the player is behind a target.
-- @tparam MobMetadata target Target mob
-- @treturn Bool True if the player is behind the target mob and false otherwise.
function geometry_util.is_behind(target)
	local direction = geometry_util.target_direction(windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id))
	local target_direction = geometry_util.target_direction(target)

	return math.abs(direction - target_direction) < 0.2
end

-------
-- Determines if the player is in front of a target.
-- @tparam MobMetadata target Target mob
-- @treturn Bool True if the player is in front of the target mob and false otherwise.
function geometry_util.is_in_front(target)
	local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)
	return math.abs((target.facing - player.facing) - math.pi) < (math.pi / 12.0)
end

-------
-- Returns the distance between two mobs, including the z-axis.
-- @tparam MobMetadata target Target mob
-- @tparam MobMetadata self Self mob
-- @treturn number Distance in yalms
function geometry_util.xyz_accurate_distance(target, self)
	local x = target.x - self.x
	local y = target.y - self.y
	local z = target.z - self.z
	return math.sqrt(x*x + y*y + z*z)
end

return geometry_util
