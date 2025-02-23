local DisposeBag = require('cylibs/events/dispose_bag')
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

    self.database = Database.new(windower.addon_path..'data/settings.db')
    self.tables = {}
    self.dispose_bag = DisposeBag.new()
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
            },
        }),
        User = Table(self.database, {
            table_name = "users",
            schema = {
                id = "INTEGER PRIMARY KEY UNIQUE",
                name = "VARCHAR(64)",
            }
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
                visible = "TINYINT(1) DEFAULT 1",
                user_id = "INTEGER",
            }
        }),
    }

    return self
end

function Settings:destroy()
    self.database:close()
    self.dispose_bag:destroy()
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
    Widget = Settings.shared().tables.Widget
}