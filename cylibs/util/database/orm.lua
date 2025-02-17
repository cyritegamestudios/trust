-- Author: Aldros-FFXI
-- Version: 1.0.0

local localization_util = require('cylibs/util/localization_util')

--- Import the sqlite3 library
local sqlite3 = require("sqlite3")

--- ORM class
local ORM = {}
ORM.__index = ORM

--- Creates a new ORM instance
-- @param database Path to the SQLite database. This is relative to FFXI's exeuction directory.
-- @return A new ORM instance
function ORM.new(database)
    local self = setmetatable({}, ORM)
    self.db = sqlite3.open(database)
    if not self.db then
        error("Failed to open database")
    end
    self.models = {}
    return self
end

--- Closes the ORM's database connection
function ORM:close()
    if self.db then
        self.db:close()
        self.db = nil
    end
end

--- Creates or retrieves a table model
-- @param table_name The name of the table
-- @param schema The schema for the table (optional)
-- @return A reference to the table's model
function ORM:Table(table_name, schema)
    if not self.models[table_name] then
        if schema then
            local schema_str = localization_util.commas(schema, "")
            -- Create the table if it doesn't exist
            local create_stmt = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", table_name, schema_str)
            self.db:exec(create_stmt)

            -- Define the Model for this table
            self.models[table_name] = function(...)
                return self.Model.new(self.db, table_name, ...)
            end
        else
            error("Schema required for new table")
        end
    elseif schema then
        -- Check if the existing table schema differs
        local check_stmt = string.format("PRAGMA table_info(%s)", table_name)
        local existing_schema = {}
        for row in self.db:nrows(check_stmt) do
            if row.pk == 1 then
                table.insert(existing_schema, row.name .. " " .. row.type .. " " .. "PRIMARY KEY")
            else
                table.insert(existing_schema, row.name .. " " .. row.type)
            end
        end
        existing_schema = S(existing_schema)
        if existing_schema ~= S(schema) then
            print(string.format("Warning: Schema for table '%s' differs from the provided schema: %s", table_name, existing_schema:sdiff(S(schema))))
        end
    end
    return self.models[table_name]
end
count = 0
--- Model class under ORM
ORM.Model = {}
ORM.Model.__index = ORM.Model

--- Creates a new Model instance. This is an internal function and shouldn't be called directly.
-- Use ORM:Table() instead since that contains proper validation.
-- @param db The SQLite database connection
-- @param table_name The name of the table
-- @param ... Optional rows to initialize the model with
-- @return A new Model instance
function ORM.Model.new(db, table_name, ...)
    local self = setmetatable({}, ORM.Model)
    self.db = db
    self.table_name = table_name
    self.rows = {...}
    return self
end

--- Saves the rows in the model to the database, updating any incomplete rows with default values from the database
-- @return The model instance
function ORM.Model:save()
    for _, row in ipairs(self.rows) do
        local columns, values = {}, {}
        for k, v in pairs(row) do
            table.insert(columns, k)
            table.insert(values, string.format("'%s'", v))
        end
        local insert_stmt = string.format(
                "INSERT INTO %s (%s) VALUES (%s)",
                self.table_name,
                table.concat(columns, ", "),
                table.concat(values, ", ")
        )
        self.db:exec(insert_stmt)

        -- Update the row with default values from the database
        local row_id = self.db:last_insert_rowid()
        local query = string.format("SELECT * FROM %s WHERE rowid = %d", self.table_name, row_id)
        for db_row in self.db:nrows(query) do
            for k, v in pairs(db_row) do
                row[k] = v
            end
        end
    end
    return self
end

--- Queries the database and populates the model with matching rows.
-- Note: this is destructive to data previously in memory.
-- @param expr A SQL WHERE clause expression specifying the rows to retrieve
-- @return The model instance
function ORM.Model:where(expr, columns)
    columns = localization_util.commas(columns or L{ "*" }, "")
    local rows = {}
    local query = string.format("SELECT %s FROM %s WHERE %s", columns, self.table_name, expr)
    for row in self.db:nrows(query) do
        table.insert(rows, row)
    end
    self.rows = rows
    return self
end

--- Adds rows matching the expression to the existing model rows
-- Note: this adds the matching rows to the in-memory rows.
-- @param expr A SQL WHERE clause expression specifying the rows to retrieve
-- @return The model instance
function ORM.Model:addwhere(expr)
    local query = string.format("SELECT * FROM %s WHERE %s", self.table_name, expr)
    for row in self.db:nrows(query) do
        table.insert(self.rows, row)
    end
    return self
end

--- Retrieves the first row from the model
-- @return A new model instance containing the first row
function ORM.Model:first()
    if #self.rows > 0 then
        return ORM.Model.new(self.db, self.table_name, self.rows[1])
    else
        return ORM.Model.new(self.db, self.table_name)
    end
end

--- Deletes the rows in the model from the database
-- Note: this does not delete them from the in-memory copy
-- @return The model instance
function ORM.Model:delete()
    for _, row in ipairs(self.rows) do
        local conditions = {}
        for k, v in pairs(row) do
            table.insert(conditions, string.format("%s='%s'", k, v))
        end
        local delete_stmt = string.format("DELETE FROM %s WHERE %s", self.table_name, table.concat(conditions, " AND "))
        self.db:exec(delete_stmt)
    end
    return self
end

--- Checks and returns the sync status and values of each row
-- @return A table containing the sync status and row values
function ORM.Model:sync_status()
    local status = {}
    for _, row in ipairs(self.rows) do
        local is_synced = true
        for k, v in pairs(row) do
            local query = string.format("SELECT %s FROM %s WHERE %s='%s'", k, self.table_name, k, v)
            local exists = false
            for db_row in self.db:nrows(query) do
                if db_row[k] ~= v then
                    is_synced = false
                end
                exists = true
                break
            end
            if not exists then
                is_synced = false
            end
        end
        table.insert(status, {synced = is_synced, row = row})
    end
    return status
end

--- Converts the model rows to a string representation, using sync_status to show their synced status and values
-- @return A string representation of the model rows
function ORM.Model:__tostring()
    local output = {}
    for _, entry in ipairs(self:sync_status()) do
        local row = entry.row
        local is_synced = entry.synced
        local row_values = {}
        for k, v in pairs(row) do
            table.insert(row_values, string.format("%s='%s'", k, v))
        end
        table.insert(output, string.format("{%s} (Synced: %s)", table.concat(row_values, ", "), tostring(is_synced)))
    end
    return table.concat(output, "\n")
end

--- Return as a module
return ORM