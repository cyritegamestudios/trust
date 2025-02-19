local DisposeBag = require('cylibs/events/dispose_bag')
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

    self.database = sqlite3.open(windower.addon_path..'data/settings.db')
    self.dispose_bag = DisposeBag.new()
    self.events = {}
    self.events.unload = windower.register_event('unload', function()
        self:destroy()
    end)

    local Users = require('settings/tables/users')
    self.users = Users.new(self.database)

    local Widgets = require('settings/tables/widgets')
    self.widgets = Widgets.new(self.database)

    self.dispose_bag:addAny(L{ self.users, self.widgets })

    return self
end

function Settings:destroy()
    self.database:close()
    self.dispose_bag:destroy()
end

return Settings