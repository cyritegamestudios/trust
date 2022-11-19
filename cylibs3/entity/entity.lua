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
    return self
end

-------
-- Returns the mob id.
-- @treturn number Mob id
function Entity:get_id()
    return self.id
end

-------
-- Returns the full mob metadata.
-- @treturn MobMetadata Mob metadata
function Entity:get_mob()
    return windower.ffxi.get_mob_by_id(self.id)
end

-------
-- Returns the full mob metadata.
-- @treturn MobMetadata Mob metadata
function Entity:get_mob()
    return windower.ffxi.get_mob_by_id(self.id)
end

return Entity