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