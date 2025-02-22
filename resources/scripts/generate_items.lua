-- Require the SQLite module
--local sqlite3 = require("sqlite3")

require('cylibs/util/database/lsqlite3')

-- Function to parse the Lua file and extract the item metadata
local function parse_lua_file(file_path)
    local chunk, err = loadfile(file_path)
    if not chunk then
        error("Error loading Lua file: " .. err)
    end

    local items = chunk()  -- Execute the chunk and retrieve the table
    if type(items) ~= "table" then
        error("Expected a table of items in Lua file.")
    end
    return items
end

-- Function to create the SQLite database and table
local function create_database(db_path)
    local db = sqlite3.open(db_path)
    db:exec([[
        CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY,
            en TEXT,
            ja TEXT,
            enl TEXT,
            jal TEXT,
            category TEXT,
            flags INTEGER,
            stack INTEGER,
            targets INTEGER,
            type INTEGER,
            cast_time REAL,
            jobs INTEGER,
            level INTEGER,
            races INTEGER,
            slots INTEGER,
            cast_delay REAL,
            max_charges INTEGER,
            recast_delay REAL,
            shield_size INTEGER,
            damage INTEGER,
            delay INTEGER,
            skill INTEGER,
            ammo_type TEXT,
            range_type TEXT,
            item_level INTEGER,
            superior_level INTEGER
        );
    ]])
    return db
end

-- Function to insert item data into the SQLite database
local function insert_item_data(db, item)
    item.id = item.id or 0
    item.en = item.en or "Unknown"
    item.ja = item.ja or "Unknown"
    item.enl = item.enl or "Unknown"
    item.jal = item.jal or "Unknown"
    item.category = item.category or "Unknown"
    item.flags = item.flags or 0
    item.stack = item.stack or 0
    item.targets = item.targets or 0
    item.type = item.type or 0
    item.cast_time = item.cast_time or 0.0
    item.jobs = item.jobs or 0
    item.level = item.level or 0
    item.races = item.races or 0
    item.slots = item.slots or 0
    item.cast_delay = item.cast_delay or 0
    item.max_charges = item.max_charges or 0
    item.recast_delay = item.recast_delay or 0
    item.shield_size = item.shield_size or 0
    item.damage = item.damage or 0
    item.delay = item.delay or 0
    item.skill = item.skill or 0
    item.ammo_type = item.ammo_type or "Unknown"
    item.range_type = item.range_type or "Unknown"
    item.item_level = item.item_level or 0
    item.superior_level = item.superior_level or 0

    -- Prepare the SQL statement with placeholders
    local insert_sql = [[
        INSERT INTO items (id, en, ja, enl, jal, category, flags, stack, targets, type,
                           cast_time, jobs, level, races, slots, cast_delay, max_charges,
                           recast_delay, shield_size, damage, delay, skill, ammo_type,
                           range_type, item_level, superior_level)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]

    -- Prepare the statement
    local stmt = db:prepare(insert_sql)
    if not stmt then
        print("Error preparing statement:", db:errmsg())
        return
    end

    -- Bind the values to the placeholders
    stmt:bind_values(
            item.id, item.en, item.ja, item.enl, item.jal, item.category, item.flags,
            item.stack, item.targets, item.type, item.cast_time, item.jobs, item.level,
            item.races, item.slots, item.cast_delay, item.max_charges, item.recast_delay,
            item.shield_size, item.damage, item.delay, item.skill, item.ammo_type,
            item.range_type, item.item_level, item.superior_level
    )

    -- Execute the query
    local res = stmt:step()
    if res == sqlite3.DONE then
        --print("Data inserted successfully for item ID: " .. item.id)
    else
        print("Error inserting data for item ID: " .. item.id .. " Error: " .. db:errmsg())
    end

    -- Finalize the statement
    stmt:finalize()
end

-- Main function to load the Lua file and insert data into the SQLite database
local function main(lua_file, db_file)
    -- Parse the Lua file
    local items = parse_lua_file(lua_file)

    -- Create the database
    local db = create_database(db_file)

    -- Insert each item into the database
    for _, item in pairs(items) do
        insert_item_data(db, item)
    end

    print("Verifying data in the table...")
    local query = "SELECT * FROM items LIMIT 1;"  -- Adjust the table name if necessary
    for row in db:nrows(query) do
        -- Print the first row to verify data
        print("Row found:", row.id, row.name)  -- Adjust according to your table structure
    end

    -- If no rows were found, print a message
    print("Data verification complete.")

    -- Close the database
    db:close()

    print("Data has been inserted into the SQLite database.")
end

-- Call the main function with your Lua file and the SQLite database file
local lua_file = "../../../../res/items.lua"
local db_file = "items.db"  -- Path to the SQLite database file

main(lua_file, db_file)
