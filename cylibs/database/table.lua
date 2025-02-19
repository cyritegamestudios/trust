local sqlite3 = require("sqlite3")

local DatabaseTable = {}
DatabaseTable.__index = DatabaseTable

function DatabaseTable.new(database, table_name, schema, primary_key)
    local self = setmetatable({}, DatabaseTable)

    self.db = database
    self.table_name = table_name
    self.schema = schema

    self:create_table(primary_key)

    return self
end

function DatabaseTable:destroy()
end

function DatabaseTable:create_table(primary_key)
    local columns = {}
    local primary_key
    for name, type in pairs(self.schema) do
        if name == "PRIMARY KEY" then
            primary_key = type
        else
            table.insert(columns, name .. " " .. type)
        end
    end
    local query
    if primary_key then
        query = string.format("CREATE TABLE IF NOT EXISTS %s (%s, PRIMARY KEY %s);", self.table_name, table.concat(columns, ", "), primary_key)
    else
        query = string.format("CREATE TABLE IF NOT EXISTS %s (%s);", self.table_name, table.concat(columns, ", "))
    end
    self.db:exec(query)
end

function DatabaseTable:insert(data)
    local columns, values, placeholders = {}, {}, {}
    for k, v in pairs(data) do
        table.insert(columns, k)
        table.insert(values, v)
        table.insert(placeholders, "?")
    end

    local query = string.format("INSERT INTO %s (%s) VALUES (%s);", self.table_name, table.concat(columns, ", "), table.concat(placeholders, ", "))
    local stmt = self.db:prepare(query)

    if stmt then
        local i = 1
        for _, v in pairs(values) do
            stmt:bind(i, v)
            i = i + 1
        end
        stmt:step()
        stmt:finalize()
    end
end

function DatabaseTable:update(data, where_clause, where_params)
    local updates, params = {}, {}
    for k, v in pairs(data) do
        table.insert(updates, k .. " = ?")
        table.insert(params, v)
    end

    local query = string.format("UPDATE %s SET %s WHERE %s;", self.table_name, table.concat(updates, ", "), where_clause)
    local stmt = self.db:prepare(query)

    if stmt then
        local i = 1
        for _, v in pairs(params) do
            stmt:bind(i, v)
            i = i + 1
        end
        for _, v in ipairs(where_params) do
            stmt:bind(i, v)
            i = i + 1
        end
        stmt:step()
        stmt:finalize()
    end
end

function DatabaseTable:upsert(data)
    local columns, values = {}, {}

    for k, v in pairs(data) do
        table.insert(columns, k)
        if type(v) == "string" then
            table.insert(values, string.format("'%s'", v:gsub("'", "''")))
        else
            table.insert(values, v)
        end
    end

    local query = string.format([[
        INSERT OR REPLACE INTO %s (%s)
        VALUES (%s)
    ]], self.table_name, table.concat(columns, ", "), table.concat(values, ", "))

    local stmt = self.db:prepare(query)
    if stmt then
        local result = stmt:step()
        if result ~= sqlite3.DONE then
            addon_system_error("Unable to save to database: "..self.db:errmsg())
        end
        stmt:finalize()
    end
end

function DatabaseTable:delete(where_clause, where_params)
    local query = string.format("DELETE FROM %s WHERE %s;", self.table_name, where_clause)
    local stmt = self.db:prepare(query)

    if stmt then
        for i, v in ipairs(where_params) do
            stmt:bind(i, v)
        end
        stmt:step()
        stmt:finalize()
    end
end

function DatabaseTable:query(where_clause)
    local where_parts = {}, {}

    for k, v in pairs(where_clause) do
        if type(v) == "string" then
            v = string.format("'%s'", v:gsub("'", "''"))  -- Escape single quotes
        end
        table.insert(where_parts, string.format("%s = %s", k, v))
    end

    local query = string.format("SELECT * FROM %s WHERE %s", self.table_name, table.concat(where_parts, " AND "))
    local results = {}

    local stmt = self.db:prepare(query)
    if stmt then
        for row in stmt:nrows() do
            table.insert(results, row)
        end
        stmt:finalize()
    end

    return L(results)
end

function DatabaseTable:close()
    self.db:close()
end

return DatabaseTable
