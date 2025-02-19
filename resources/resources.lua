local ORM = require('cylibs/database/orm/orm')

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

    self.database = ORM.new(windower.addon_path..'resources/resources.db')
    self.events = {}
    self.events.unload = windower.register_event('unload', function()
        self:destroy()
    end)

    local Items = require('resources/items')
    self.items = Items.new(self.database)

    return self
end

function Resources:destroy()
    self.database:close()
end

windower.trust.resources = Resources.shared()
windower.trust.res = Resources.shared()

return Resources