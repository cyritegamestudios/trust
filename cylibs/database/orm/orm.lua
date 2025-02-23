local Event = require('cylibs/events/Luvent')
local sqlite3 = require("sqlite3")

local Model = {}
Model.__index = Model

local ORM = {}
ORM.__index = ORM

function ORM.new(db_name)
    local self = setmetatable({}, ORM)
    self.db = sqlite3.open(db_name)
    self.tables = {}
    return self
end

function ORM:destroy()
    self.db:close()
end

function ORM:execute(sql, ...)
    local stmt = self.db:prepare(sql)
    if not stmt then
        error("Failed to prepare statement: " .. sql)
    end
    stmt:bind_values(...)
    stmt:step()
    stmt:finalize()
end

function ORM:create_table(model)
    local columns = {}
    for col, col_type in pairs(model.schema) do
        table.insert(columns, col .. " " .. col_type)
    end
    local sql
    if model.primary_key then
        sql = string.format("CREATE TABLE IF NOT EXISTS %s (%s, PRIMARY KEY %s);", model.table_name, table.concat(columns, ", "), model.primary_key)
    else
        sql = string.format("CREATE TABLE IF NOT EXISTS %s (%s);", model.table_name, table.concat(columns, ", "))
    end
    --if model.foreign_keys then
    --    sql = sql..' '..string.format("%s", table.concat(model.foreign_keys, "\n"))
    --end
    --sql = sql..";"
    self:execute(sql)
end

function ORM:insert(table_name, data)
    local columns, values, placeholders = {}, {}, {}
    for col, val in pairs(data) do
        table.insert(columns, col)
        table.insert(values, val)
        table.insert(placeholders, "?")
    end
    local sql = string.format("INSERT INTO %s (%s) VALUES (%s);", table_name, table.concat(columns, ", "), table.concat(placeholders, ", "))
    self:execute(sql, table.unpack(values))
end

function ORM:select(table_name, conditions, fields, raw_rows)
    local columns = "*"
    if fields and fields:length() > 0 then
        columns = table.concat(fields)
    end

    local sql = string.format("SELECT %s FROM %s", columns, table_name)
    local where_clause = {}

    if conditions then
        if type(conditions) == 'string' then
            sql = sql .. " WHERE "..conditions
        else
            for col, val in pairs(conditions) do
                if type(val) == "string" then
                    val = "'" .. val:gsub("'", "''") .. "'" -- Escape single quotes in strings
                end
                table.insert(where_clause, col .. " = " .. val)
            end
            sql = sql .. " WHERE " .. table.concat(where_clause, " AND ")
        end
    end
    sql = sql .. ";"
    local result = L{}
    for row in self.db:nrows(sql) do
        result:append(row)
    end
    if not raw_rows then
        result = result:map(function(row)
            return Model.new(self.tables[table_name], row)
        end)
    end
    return result
end

function ORM:update(table_name, data, conditions)
    local set_clause, values = {}, {}
    for col, val in pairs(data) do
        table.insert(set_clause, col .. " = ?")
        table.insert(values, val)
    end
    local sql = "UPDATE " .. table_name .. " SET " .. table.concat(set_clause, ", ")
    if conditions then
        local where_clause = {}
        for col, val in pairs(conditions) do
            table.insert(where_clause, col .. " = ?")
            table.insert(values, val)
        end
        sql = sql .. " WHERE " .. table.concat(where_clause, " AND ")
    end
    sql = sql .. ";"
    self:execute(sql, table.unpack(values))
end

function ORM:delete(table_name, conditions)
    local sql = "DELETE FROM " .. table_name
    local where_clause, values = {}, {}
    if conditions then
        for col, val in pairs(conditions) do
            table.insert(where_clause, col .. " = ?")
            table.insert(values, val)
        end
        sql = sql .. " WHERE " .. table.concat(where_clause, " AND ")
    end
    sql = sql .. ";"
    self:execute(sql, table.unpack(values))
end

function ORM:close()
    self.db:close()
end

-- Row Object with Save/Delete functionality
ORM.Row = {}
ORM.Row.__index = ORM.Row

function ORM.Row:save()
    local data, conditions = {}, {}
    for k, v in pairs(self) do
        if k ~= "_table_name" and k ~= "_db" then
            if k == "id" then
                conditions[k] = v
            else
                data[k] = v
            end
        end
    end
    self._db:update(self._table_name, data, conditions)
end

function ORM.Row:delete()
    self._db:delete(self._table_name, { id = self.id })
end

function Model.new(table, data)
    local self = setmetatable({}, Model)
    self.table = table
    for key, value in pairs(data or {}) do
        self[key] = value
    end
    return self
end

function Model:save()
    --[[local data, conditions = {}, {}
    for k, v in pairs(self) do
        if k ~= "table" then
            if k == self.table.primary_key or k == "id" then
                conditions[k] = v
            end
            data[k] = v
        end
    end
    self.table:update(data, conditions)]]
    local data, conditions = {}, {}

    local primary_key = self.table.primary_key or "id"

    -- Parse composite primary key string into a table
    local primary_keys = {}
    for key in string.gmatch(primary_key, "[%w_]+") do
        table.insert(primary_keys, key)
    end

    -- Collect primary key values for conditions
    for _, key in ipairs(primary_keys) do
        conditions[key] = self[key]
    end

    -- Collect all column values except the table reference
    for k, v in pairs(self) do
        if k ~= "table" and k ~= "primary_key" then
            data[k] = v
        end
    end

    -- If all primary key fields exist, attempt an update, otherwise insert
    local existing = self.table:where(conditions)

    if #existing > 0 then
        self.table:update(data, conditions)
    else
        self.table:insert(data)
    end
end

function Model:saveSettings()
    self:save()
end

local Table = {}
Table.__index = Table
Table.__call = Model.new
Table.__type = "Table"

setmetatable(Table, {
    __call = function(_, orm, config)
        return Table.new(orm, config)
    end
})

function Table:on_row_updated()
    return self.row_updated
end

function Table.new(orm, config)
    local self = setmetatable({}, Table)

    self.orm = orm
    self.table_name = config.table_name
    self.schema = config.schema
    self.primary_key = config.primary_key
    self.row_updated = Event.newEvent()

    self.orm:create_table(config)

    self.orm.tables[self.table_name] = self

    if config.migrations ~= nil then
        config.migrations(self)
    end

    return self
end

function Table:all()
    return self.orm:select(self.table_name)
end

function Table:get(conditions, fields, raw_rows)
    local result = self.orm:select(self.table_name, conditions, fields, raw_rows)
    return #result > 0 and result[1] or nil
end

function Table:where(conditions, fields, raw_rows)
    return self.orm:select(self.table_name, conditions, fields, raw_rows)
end

function Table:update(data, conditions)
    self.orm:update(self.table_name, data, conditions)
end

function Table:insert(data)
    self.orm:insert(self.table_name, data)
end

function Table:delete(conditions)
    self.orm:delete(self.table_name, conditions)
end

function Table:initialize(orm)
    self.orm = orm
    orm:create_table(self)
end

function Table:column_exists(column_name)
    local query = string.format("PRAGMA table_info(%s);", self.table_name)
    for row in self.orm.db:nrows(query) do
        if row.name == column_name then
            return true
        end
    end
    return false
end

function Table:add_column(column_name, column_type, default)
    if self:column_exists(column_name) then
        return
    end
    local stmt = string.format("ALTER TABLE %s ADD COLUMN %s %s", self.table_name, column_name, column_type)
    if default then
        stmt = string.format("%s DEFAULT %s", stmt, default)
    end
    self.orm:execute(stmt..";")
end

return { ORM = ORM, Table = Table }
