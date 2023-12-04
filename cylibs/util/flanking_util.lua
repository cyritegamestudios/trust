---------------------------
-- Utility functions for getting vector positions around a target
-- @class module
-- @name FlankingUtil

_libs = _libs or {}

require("math")
require('vectors')

local flanking_util = {}

_raw = _raw or {}

_libs.flanking_util = flanking_util

flanking_util.Back = "back"
flanking_util.Left = "left"
flanking_util.Right = "right"

-------
-- Gets a relative location around a target, given a string back/left/right gets a point at
-- the given distance and angle. Note this does not check who the mob is targeting, so
-- there is a potential edge case if someone were to attempt to move to the back of a mob that
-- is targeting them and will turn to them
-- @tparam number mob_id ID of a mob to retrieve locations for
-- @tparam string angle One of "back", "left", "right", to determine which relative location to return
-- @tparam number distance Distance from the mob to calculate points for
-- @treturn vector A vector location relative to the mob at a given distance or nil
function flanking_util.get_relative_location_for_target(mob_id, angle, distance)
    -- get mob, should have location and facing
    local mob = windower.ffxi.get_mob_by_id(mob_id)
    if not mob then return nil end -- If we can't get the mob, return nil
    -- if not not battle_util.is_valid_target(mob_id) then return nil end -- If not valid target, ignore, may not need

    -- Get the unit vector for the mob, due to a FFXI angle quirk, use negative angles
    local u = V{math.cos(-mob.facing), math.sin(-mob.facing), mob.z}

    -- Get a distance relative to mob size
    local my_size = windower.ffxi.get_mob_by_target('me').model_size or 0
    local d = mob.model_size + my_size + distance

    local locations = {
        back = V{ mob.x - d * u[1], mob.y - d * u[2], mob.z },
        left = V{ mob.x - d * u[2], mob.y + d * u[1], mob.z },
        right = V{ mob.x + d * u[2], mob.y - d * u[1], mob.z },
    }

    -- since we calculated them all, can just return, and it'll return nil in other cases, easy!
    return locations[angle]

end

-------
-- Gets the closest point to a target within a given radius not overlapped by a given radius from
-- a second target
-- @tparam number target_1_id ID of the first target, which will be the center of the inclusion area
-- @tparam number distance_1 Radius of the first target's inclusion range
-- @tparam number target_2_id ID of the second target, which will be the center of the exclusion area
-- @tparam number distance_2 Radius of the second target's exclusion range
-- @treturn vector An (x,y,z) vector location that is within distance_1 of target_1 and not within distance_2 of target_2
function flanking_util.get_closest_point_relative_to_two_targets(target_1_id, distance_1, target_2_id, distance_2)
    notice("Not yet implemented function")
end



return flanking_util
