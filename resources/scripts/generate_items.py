import sys
import sqlite3
import shutil
import os
from lupa import LuaRuntime

ALLOWED_STATS = {
    'STR': 'STR',
    'DEX': 'DEX',
    'AGI': 'AGI',
    'INT': 'INT',
    'CHR': 'CHR',
    'VIT': 'VIT',
    'MND': 'MND',
    'DEF': 'DEF',
    'HP': 'HP',
    'MP': 'MP',
    'Attack': 'Attack',
    'Ranged Attack': 'Ranged_Attack',
    'Magic Atk. Bonus': 'Magic_Attack',
    'Accuracy': 'Accuracy',
    'Ranged Accuracy': 'Ranged_Accuracy',
    'Magic Accuracy': 'Magic_Accuracy',
    'Evasion': 'Evasion',
    'Magic Evasion': 'Magic_Evasion',
    'Magic Def. Bonus': 'Magic_Defense_Bonus'
}

def parse_lua_file(lua_file_path):
    lua = LuaRuntime(unpack_returned_tuples=True)
    with open(lua_file_path, 'r') as f:
        lua_code = f.read()

    # Execute Lua code directly, returns a tuple of (items, fields)
    item_table, field_names = lua.execute(lua_code)
    return item_table

def parse_description_file(lua_file_path):
    lua = LuaRuntime(unpack_returned_tuples=True)
    with open(lua_file_path, 'r', encoding='utf-8') as f:
        lua_code = f.read()

    description_table, _ = lua.execute(lua_code)
    return description_table

def create_items_table(conn):
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

def create_description_table(conn):
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS item_descriptions (
            id INTEGER PRIMARY KEY,
            en TEXT,
            ja TEXT,
            STR INTEGER,
            DEX INTEGER,
            AGI INTEGER,
            INT INTEGER,
            CHR INTEGER,
            VIT INTEGER,
            MND INTEGER,
            DEF INTEGER,
            HP INTEGER,
            MP INTEGER,
            Attack INTEGER,
            Ranged_Attack INTEGER,
            Magic_Attack INTEGER,
            Accuracy INTEGER,
            Ranged_Accuracy INTEGER,
            Magic_Accuracy INTEGER,
            Evasion INTEGER,
            Magic_Evasion INTEGER,
            Magic_Defense_Bonus INTEGER
        );
    """)
    conn.commit()

def create_database(db_file):
    conn = sqlite3.connect(db_file)
    create_items_table(conn)
    create_description_table(conn)
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
        INSERT OR REPLACE INTO items ({','.join(fields)})
        VALUES ({placeholders})
    """, values)


def extract_stats(description_en):
    if not description_en:
        return {}

    description_en = description_en.replace('\n', ' ')
    stats = {}

    # Pattern: label followed by +number (e.g., STR+10, Magic Accuracy+7)
    pattern = re.compile(r'([A-Za-z. ]+?)(?:\s*\+|\s*:\s*)([-+]?\d+)(%?)\b')

    for match in pattern.finditer(description_en):
        raw_key, value, _ = match.groups()
        key = raw_key.strip()
        normalized_key = ALLOWED_STATS.get(key)
        if normalized_key:
            try:
                stats[normalized_key] = int(value)
            except ValueError:
                pass  # silently ignore bad values

    return stats

def insert_description(conn, id, en, ja):
    stats = extract_stats(en)

    # Base fields
    columns = ['id', 'en', 'ja']
    values = [id, en, ja]

    # Add any stat columns and values
    for col in [
        'STR', 'DEX', 'AGI', 'INT', 'CHR', 'VIT', 'MND', 'DEF', 'HP', 'MP',
        'Attack', 'Ranged_Attack', 'Magic_Attack', 'Accuracy',
        'Ranged_Accuracy', 'Magic_Accuracy', 'Evasion',
        'Magic_Evasion', 'Magic_Defense_Bonus'
    ]:
        columns.append(col)
        values.append(stats.get(col))

    placeholders = ', '.join(['?'] * len(values))
    col_string = ', '.join(columns)

    conn.execute(f"""
        INSERT OR REPLACE INTO item_descriptions ({col_string})
        VALUES ({placeholders})
    """, values)

def main():
    lua_file = sys.argv[1]
    db_file = sys.argv[2]
    description_file = sys.argv[3]

    items = parse_lua_file(lua_file)
    descriptions = parse_description_file(description_file)
    conn = create_database(db_file)

    for key, item in items.items():
        insert_item(conn, item)

    for id, desc in descriptions.items():
        insert_description(conn, int(id), desc['en'], desc['ja'])

    conn.commit()
    print("Inserted all items.")
    conn.close()

    # Copy to resources/resources.db
    output_path = "resources/resources.db"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    shutil.copyfile(db_file, output_path)
    print(f"Database copied to {output_path}")

if __name__ == "__main__":
    main()
