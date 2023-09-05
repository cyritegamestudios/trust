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
-- Returns the mob name
-- @treturn string Mob name
function Entity:get_name()
    return self.name or self:get_mob().name
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

-------
-- Returns whether the mob is in memory.
-- @treturn Boolean True if the mob is in memory.
function Entity:is_valid()
    return self:get_mob() ~= nil
end

return Entity