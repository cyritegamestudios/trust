local bit = require('bit')

local Items = {}
Items.__index = Items

Items.Filter = {}
Items.Filter.Usable = "category == 'Usable'"
Items.Filter.Stackable = "stack == 99"

function Items.new(database)
    local self = setmetatable({}, Items)

    self.database = database
    self.database:Table(self:get_table_name(), self:get_schema())

    return self
end

function Items:get_schema()
    local columns = L {
        "id INTEGER PRIMARY KEY",
        "en TEXT",
        "ja TEXT",
        "enl TEXT",
        "jal TEXT",
        "category TEXT",
        "flags INTEGER",
        "stack INTEGER",
        "targets INTEGER",
        "type INTEGER",
        "cast_time REAL",
        "jobs INTEGER",
        "level INTEGER",
        "races INTEGER",
        "slots INTEGER",
        "cast_delay REAL",
        "max_charges INTEGER",
        "recast_delay REAL",
        "shield_size INTEGER",
        "damage INTEGER",
        "delay INTEGER",
        "skill INTEGER",
        "ammo_type TEXT",
        "range_type TEXT",
        "item_level INTEGER",
        "superior_level INTEGER"
    }
    return columns
end

function Items:get_table_name()
    return "items"
end

function Items:get_table()
    return self.database:Table(self:get_table_name())
end

function Items:post_process(result)
    if result.rows then
        for _, row in pairs(result.rows) do
            if row.slots then
                local slots = L{}
                for i = 0, 15 do
                    local mask = bit.lshift(1, i)
                    if bit.band(tonumber(mask), row.slots) ~= 0 then
                        slots:append(i)
                    end
                end
                row.slots = slots
            end
        end
    end
end

function Items:where(query, fields)
    local table = self:get_table()
    local result = table():where(query, fields)
    if result.rows then
        self:post_process(result)
        return L(result.rows)
    end
    return L{}
end

function Items:with(key, value, fields)
    local result = self:where(string.format("%s == \"%s\"", key, value), fields)
    return result and result:first()
end

function Items:named(item_name, fields)
    local result = self:where(string.format("en == \"%s\"", item_name), fields)
    return result and result:first()
end

function Items:with_category(category, fields)
    local table = self:get_table()
    local result = table():where(string.format("category == \"%s\"", category), fields)
    if result.rows then
        return L(result.rows)
    end
    return L{}
end

return Items