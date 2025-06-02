local ORM = require('cylibs/database/orm/orm')
local Database = ORM.ORM
local Table = ORM.Table

local sqlite3 = require("sqlite3")

local Settings = {}
Settings.__index = Settings

---
-- Creates a new Settings instance.
--
-- @treturn Settings The newly created Settings instance.
--
function Settings.new()
    local self = setmetatable({}, Settings)

    self.database = Database.new(windower.addon_path..'data', 'settings.db')
    self.tables = {}
    self.events = {}
    self.events.unload = windower.register_event('unload', function()
        self:destroy()
    end)

    self.tables = {
        Shortcut = Table(self.database, {
            table_name = "shortcuts",
            schema = {
                id = "VARCHAR(64) PRIMARY KEY UNIQUE",
                key = "VARCHAR(8) DEFAULT A UNIQUE",
                flags = "INTEGER DEFAULT 1",
                enabled = "TINYINT(1) DEFAULT 1",
                command = "VARCHAR(64)",
                description = "VARCHAR(64)"
            },
            migrations = function(table)
                table:add_column("command", "VARCHAR(64)")
                table:add_column("description", "VARCHAR(64)")
            end
        }),
        User = Table(self.database, {
            table_name = "users",
            schema = {
                id = "INTEGER PRIMARY KEY UNIQUE",
                name = "VARCHAR(64)",
                is_whitelisted = "TINYINT(1) DEFAULT 1",
            },
        }),
        Widget = Table(self.database, {
            table_name = "widgets",
            primary_key = "(name, user_id)",
            foreign_keys = {
            },
            schema = {
                name = "VARCHAR(64)",
                x = "INTEGER",
                y = "INTEGER",
                visible = "TINYINT(1) DEFAULT 0",
                user_id = "INTEGER",
            }
        }),
        Whitelist = Table(self.database, {
            table_name = "whitelist",
            schema = {
                id = "VARCHAR(64) PRIMARY KEY UNIQUE",
            }
        }),
        EquipSet = Table(self.database, {
            table_name = "equip_sets",
            primary_key = "(name, user_id)",
            schema = {
                name = "VARCHAR(64)",
                user_id = "INTEGER",

                main = "INTEGER",
                main_ext_data = "TEXT",

                sub = "INTEGER",
                sub_ext_data = "TEXT",

                range = "INTEGER",
                range_ext_data = "TEXT",

                ammo = "INTEGER",
                ammo_ext_data = "TEXT",

                head = "INTEGER",
                head_ext_data = "TEXT",

                neck = "INTEGER",
                neck_ext_data = "TEXT",

                left_ear = "INTEGER",
                left_ear_ext_data = "TEXT",

                right_ear = "INTEGER",
                right_ear_ext_data = "TEXT",

                body = "INTEGER",
                body_ext_data = "TEXT",

                hands = "INTEGER",
                hands_ext_data = "TEXT",

                left_ring = "INTEGER",
                left_ring_ext_data = "TEXT",

                right_ring = "INTEGER",
                right_ring_ext_data = "TEXT",

                back = "INTEGER",
                back_ext_data = "TEXT",

                waist = "INTEGER",
                waist_ext_data = "TEXT",

                legs = "INTEGER",
                legs_ext_data = "TEXT",

                feet = "INTEGER",
                feet_ext_data = "TEXT",
            }
        })
    }

    return self
end

function Settings:destroy()
    self.database:destroy()
end

local instance = Settings.new()

function Settings.shared()
    if instance == nil then
        instance = Settings.new()
    end
    return instance
end

return {
    Shortcut = Settings.shared().tables.Shortcut,
    User = Settings.shared().tables.User,
    Widget = Settings.shared().tables.Widget,
    Whitelist = Settings.shared().tables.Whitelist,
    EquipSet = Settings.shared().tables.EquipSet,
}