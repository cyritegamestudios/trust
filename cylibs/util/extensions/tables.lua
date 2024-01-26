---------------------------
-- Extension on table.
-- @class module
-- @name TableExtension

_libs = _libs or {}

require('functions')

local functions = _libs.functions

local table = require('table')

_libs.tables = table

_raw = _raw or {}
_raw.table = setmetatable(_raw.table or {}, {__index = table})

--[[
    Signatures
]]

_meta = _meta or {}
_meta.T = _meta.T or {}
_meta.T.__index = table
_meta.T.__class = 'Table'

_meta.N = {}
_meta.N.__class = 'nil'

-- Finds all entries in a table based on an attribute.
function table.with_all(t, attr, val)
    local result = L{}
    val = type(val) ~= 'function' and functions.equals(val) or val
    for _, el in pairs(t) do
        if type(el) == 'table' and val(el[attr]) then
            result:append(el)
        end
    end
    return result
end

-- Finds th first entry in a table with the given name. Checks for en first and then jp.
function table.with_name_safe(t, val)
    val = type(val) ~= 'function' and functions.equals(val) or val
    for _, el in pairs(t) do
        if type(el) == 'table' and (val(el['en']) or val(el['ja'])) then
            return el
        end
    end
    return nil
end

function table.diff(t, other_table)
    local table_diff = T{}
    for key, value in pairs(t) do
        if value ~= other_table[key] then
            table_diff[key] = value
        end
    end
    return table_diff
end

function table.merge(table1, table2)
    local merged_table = table1:copy()
    for key, value in pairs(table2) do
        merged_table[key] = value
    end
    return merged_table
end

function table.clone(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for key, value in pairs(t) do
        copy[table.clone(key)] = table.clone(value)
    end
    return setmetatable(copy, getmetatable(t))
end