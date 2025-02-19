local DatabaseTable = require('cylibs/database/table')

local Widgets = setmetatable({}, {__index = DatabaseTable })
Widgets.__index = Widgets

local schema = {
    name = "VARCHAR(64) PRIMARY KEY UNIQUE", -- need this to be combbined with user_id to make unique
    x = "INTEGER",
    y = "INTEGER",
    visible = "TINYINT(1) DEFAULT 1",
    user_id = "INTEGER",
}

function Widgets.new(database)
    local self = setmetatable(DatabaseTable.new(database, "widgets", schema), Widgets)
    return self
end

return Widgets