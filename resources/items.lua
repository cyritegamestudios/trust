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

function Items:filter(filters, operator, fields)
    local query = localization_util.com
    for filter in filters:it() do
        if Items.Filter[filter] then
            query = query
        end
    end
end

function Items:where(query, fields)
    local table = self:get_table()
    local result = table():where(query, fields)
    if result.rows then
        return L(result.rows)
    end
    return L{}
end

function Items:item_with_name(item_name)
    local table = self:get_table()
    local query = string.format("en LIKE '%%%s%%'", item_name)
    local result = table():where(query)
    if result.rows then
        return L(result.rows)
    end
    return L{}
end

function Items:items_with_category(category, fields)
    local table = self:get_table()
    local result = table():where(string.format("category == \"%s\"", category), fields)
    if result.rows then
        return L(result.rows)
    end
    return L{}
end

return Items