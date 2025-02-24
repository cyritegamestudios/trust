local ORM = require('cylibs/database/orm/orm')
local Database = ORM.ORM
local Table = ORM.Table

local Resources = {}
Resources.__index = Resources

local instance

---
-- Returns the Resources singleton.
--
-- @treturn Resources The Resources singleton.
--
function Resources.shared()
    if instance == nil then
        instance = Resources.new()
    end
    return instance
end

---
-- Creates a new Resources instance.
--
-- @treturn Resources The newly created Resources instance.
--
function Resources.new()
    local self = setmetatable({}, Resources)

    self.database = Database.new(windower.addon_path..'resources', 'resources.db', true)
    self.events = {}
    self.events.unload = windower.register_event('unload', function()
        self:destroy()
    end)

    self.tables = {
        Item = Table(self.database, {
            table_name = "items",
            schema = {
                id = "INTEGER PRIMARY KEY",
                en = "TEXT",
                ja = "TEXT",
                enl = "TEXT",
                jal = "TEXT",
                category = "TEXT",
                flags = "INTEGER",
                stack = "INTEGER",
                targets = "INTEGER",
                type = "INTEGER",
                cast_time = "REAL",
                jobs = "INTEGER",
                levels = "INTEGER",
                races = "INTEGER",
                slots = "INTEGER",
                cast_delay = "REAL",
                max_charges = "INTEGER",
                recast_delay = "REAL",
                shield_size = "INTEGER",
                damage = "INTEGER",
                delay = "INTEGER",
                skill = "INTEGER",
                ammo_type = "TEXT",
                range_type = "TEXT",
                item_level = "INTEGER",
                superior_level = "INTEGER"
            },
        }),
    }

    return self
end

function Resources:destroy()
    self.database:destroy()
end

function Resources:get_table(resource_name)
    if self.tables[resource_name] then
        return self.tables[resource_name]
    end
    local resource_map = {
        items = self.tables.Item
    }
    return resource_map[resource_name]
end

local instance = Resources.new()

function Resources.shared()
    if instance == nil then
        instance = Resources.new()
    end
    return instance
end

return {
    Resources = Resources.shared(),
    Item = Resources.shared().tables.Item,
}