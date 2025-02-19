local DatabaseTable = require('cylibs/database/table')

local Users = setmetatable({}, {__index = DatabaseTable })
Users.__index = Users

local schema = {
    id = "INTEGER PRIMARY KEY UNIQUE",
    name = "VARCHAR(64)",
}

function Users.new(database)
    local self = setmetatable(DatabaseTable.new(database, "users", schema), Users)
    return self
end

function Users:create(user_id, name)
    self:upsert({ id = user_id, name = name })
end

return Users