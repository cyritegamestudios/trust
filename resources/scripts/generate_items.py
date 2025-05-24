import sys
import sqlite3
from lupa import LuaRuntime

def parse_lua_file(lua_file_path):
    lua = LuaRuntime(unpack_returned_tuples=True)
    with open(lua_file_path, 'r') as f:
        lua_code = f.read()

    # Convert Lua file into a function so we can safely call it
    lua_table_loader = lua.eval(f"function() {lua_code} end")
    items = lua_table_loader()
    return items

def create_database(db_file):
    conn = sqlite3.connect(db_file)
    c = conn.cursor()
    c.execute("""
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
    """)
    conn.commit()
    return conn

def insert_item(conn, item):
    fields = [
        'id', 'en', 'ja', 'enl', 'jal', 'category', 'flags', 'stack', 'targets', 'type',
        'cast_time', 'jobs', 'level', 'races', 'slots', 'cast_delay', 'max_charges',
        'recast_delay', 'shield_size', 'damage', 'delay', 'skill', 'ammo_type',
        'range_type', 'item_level', 'superior_level'
    ]
    defaults = {f: "Unknown" if isinstance(getattr(item, f, None), str) else 0 for f in fields}

    values = [getattr(item, f, defaults[f]) for f in fields]
    placeholders = ','.join(['?'] * len(values))
    conn.execute(f"""
        INSERT INTO items ({','.join(fields)})
        VALUES ({placeholders})
    """, values)

def main():
    lua_file = sys.argv[1]
    db_file = sys.argv[2]

    items = parse_lua_file(lua_file)
    conn = create_database(db_file)

    for key, item in items.items():
        insert_item(conn, item)

    conn.commit()
    print("Inserted all items.")
    conn.close()

if __name__ == "__main__":
    main()
