local DatabaseTable = require('cylibs/database/table')
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
    --self.database = sqlite3.open(windower.addon_path..'data/settings.db')
    self.dispose_bag = DisposeBag.new()
    self.events = {}
    self.events.unload = windower.register_event('unload', function()
        self:destroy()
    end)

    _G.User = Table(self.database, {
        table_name = "users",
        schema = {
            id = "INTEGER PRIMARY KEY UNIQUE",
            name = "VARCHAR(64)",
        }
    })

    _G.Widget = Table(self.database, {
        table_name = "widgets",
        primary_key = "(name, user_id)",
        schema = {
            name = "VARCHAR(64)",
            x = "INTEGER",
            y = "INTEGER",
            visible = "TINYINT(1) DEFAULT 1",
            user_id = "INTEGER",
        }
    })

    --[[self.users = DatabaseTable.new(self.database, "users", {
        id = "INTEGER PRIMARY KEY UNIQUE",
        name = "VARCHAR(64)",
    })]]

    --[[self.widgets = Table(self.database, {
        table_name = "widgets",
        primary_key = "(name, user_id)",
        schema = {
            name = "VARCHAR(64)",
            x = "INTEGER",
            y = "INTEGER",
            visible = "TINYINT(1) DEFAULT 1",
            user_id = "INTEGER",
        }
    })
    self.database:create_table(self.widgets)]]
    --[[self.widgets = DatabaseTable.new(self.database, "widgets", {
        name = "VARCHAR(64)",
        x = "INTEGER",
        y = "INTEGER",
        visible = "TINYINT(1) DEFAULT 1",
        user_id = "INTEGER",
        ["PRIMARY KEY"] = "(name, user_id)",
    })]]

    self.dispose_bag:addAny(L{ self.users, self.widgets })

    return self
end

function Settings:destroy()
    self.database:close()
    self.dispose_bag:destroy()
end

return Settings