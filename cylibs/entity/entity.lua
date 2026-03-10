local ffxi_util = require('cylibs/util/ffxi_util')

---------------------------
-- Base entity class.
-- @class module
-- @name Entity

local Entity = {}
Entity.__index = Entity

-------
-- Default initializer for an entity.
-- @tparam number id Mob id
-- @treturn Entity An entity
function Entity.new(id)
    local self = setmetatable({
        id = id;
    }, Entity)
    local mob = windower.ffxi.get_mob_by_id(self.id)
    if mob then
        self.name = mob.name
        self.position = ffxi_util.get_mob_position(mob.name) or V{0, 0, 0}
    end
    return self
end

-------
-- Returns the mob id.
-- @treturn number Mob id
function Entity:get_id()
    return self.id
end

-------
-- Returns the mob index.
-- @treturn number Mob index
function Entity:get_index()
    return self:get_mob() and self:get_mob().index or 0
end

-------
-- Returns the mob name
-- @treturn string Mob name
function Entity:get_name()
    return self.name or self:get_mob() and self:get_mob().name or "Unknown"
end

-------
-- Returns the distance of the entity from the player, or 9999 if the mob is nil.
-- @treturn number Distance from the player
function Entity:get_distance()
    local mob = self:get_mob()
    if mob then
        return mob.distance
    end
    return 9999
end

-------
-- Returns the full mob metadata.
-- @treturn MobMetadata Mob metadata
function Entity:get_mob()
    return windower.ffxi.get_mob_by_id(self.id)
end

-------
-- Returns whether the mob is in memory.
-- @treturn Boolean True if the mob is in memory.
function Entity:is_valid()
    local mob = self:get_mob()
    return mob ~= nil and mob.hpp > 0
end

-------
-- Returns whether the entity has resistance info.
-- @treturn Boolean True if the entity has resistance info.
function Entity:has_resistance_info()
    return false
end

-------
-- Returns the (x, y, z) coordinate of the mob.
-- @treturn vector Position of the mob, or the last known position if the mob is not valid
function Entity:get_position()
    return self.position or ffxi_util.get_mob_position(self:get_name()) or V{0, 0, 0}
end

-------
-- Sets the (x, y, z) coordinate of the mob.
-- @tparam number x X coordinate
-- @tparam number y Y coordinate
-- @tparam number z Z coordinate
function Entity:set_position(x, y, z)
    self.position = vector.zero(3)
    self.position[1] = x
    self.position[2] = y
    self.position[3] = z
end

function Entity:distance(x, y)
    local mob = self:get_mob()
    if not mob then
        return 9999
    end
    return math.sqrt((mob.x-x)^2+(mob.y-y)^2)
end

function Entity:__eq(otherItem)
    return self:get_id() == otherItem:get_id()
end


return Entity