local ItemDescriptions = {}
ItemDescriptions.__index = ItemDescriptions

function ItemDescriptions.new(database)
    local self = setmetatable({}, ItemDescriptions)

    self.database = database
    self.database:Table(self:get_table_name(), self:get_schema())

    return self
end

function ItemDescriptions:get_schema()
    local columns = L {
        "id INTEGER PRIMARY KEY",
        "en TEXT",
        "ja TEXT"
    }
    return columns
end

function ItemDescriptions:get_table_name()
    return "item_descriptions"
end

function ItemDescriptions:get_table()
    return self.database:Table(self:get_table_name())
end

function ItemDescriptions:where(query, fields)
    local table = self:get_table()
    local result = table():where(query, fields)
    if result.rows then
        return L(result.rows)
    end
    return L{}
end

function ItemDescriptions:with(key, value, fields)
    local result = self:where(string.format("%s == \"%s\"", key, value), fields)
    return result and result:first()
end

return ItemDescriptions