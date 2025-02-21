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
    self.dispose_bag = DisposeBag.new()
    self.events = {}
    self.events.unload = windower.register_event('unload', function()
        self:destroy()
    end)

    _G.Shortcut = Table(self.database, {
        table_name = "shortcuts",
        schema = {
            id = "VARCHAR(64) PRIMARY KEY UNIQUE",
            key = "VARCHAR(8) DEFAULT A",
            flags = "INTEGER DEFAULT 0",
            enabled = "TINYINT(1) DEFAULT 1",
        }
    })

    _G.User = Table(self.database, {
        table_name = "users",
        schema = {
            id = "INTEGER PRIMARY KEY UNIQUE",
            name = "VARCHAR(64)",
        }
    })

    _G.WidgetSettings = Table(self.database, {
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
    })

    _G.GeneralSettings = Table(self.database, {
        table_name = "general",
        schema = {
            id = "INTEGER",
            follow_distance = "INTEGER DEFAULT 1",
            follow_auto_pause = "TINYINT(1) DEFAULT 0",
            menu_key = "VARCHAR(8) DEFAULT '%^numpad+'",
            sounds_enabled = "TINYINT(1) DEFAULT 1",
        }
    })

    self.dispose_bag:addAny(L{ self.users, self.widgets })

    return self
end

function Settings:destroy()
    self.database:close()
    self.dispose_bag:destroy()
end

return Settings