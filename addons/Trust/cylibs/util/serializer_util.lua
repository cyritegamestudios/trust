_libs = _libs or {}

local serializer_util = {}

_raw = _raw or {}

_libs.serializer_util = serializer_util

function serializer_util.serialize(tbl, indent_level)
    indent_level = indent_level or 1 -- indent_level 0 being single-line

    local tbl_type = type(tbl)

    if tbl_type == "number" or tbl_type == "boolean" or tbl_type == "nil" then -- Easy returns, just return tostring
        return tostring(tbl)
    elseif tbl_type == "string" then
        return string.format("%q", tbl) -- %q quotes the string
    elseif tbl_type == "table" then -- If it's a table of some kind, dig into it
        local result = {}
        local result_type = nil -- Result type in for handling {} vs L{} cases
        for k, v in pairs(tbl) do
            if k ~= "n" then
                local key_str, value_str

                if type(k) == "number" then
                    key_str = nil
                    result_type = "List" -- Treat table with numeric keys as List, we can maybe implement a serializer for list, but this works for now
                else
                    if string.find(k, " ") then
                        key_str = string.format("[%q]", tostring(k))
                    else
                        key_str = tostring(k)
                    end
                end

                if type(v) == "table" and v.serialize then -- If we have a serializer for it, call it
                    value_str = v:serialize()
                else -- Otherwise increase indent_level and recursively call self
                    local new_indent_level
                    if indent_level == 0 then
                        new_indent_level = 0
                    else
                        new_indent_level = indent_level + 1
                    end
                    value_str = serializer_util.serialize(v, new_indent_level) -- recurse for table values here
                end

                local indentation -- Indentation handling
                if indent_level == 0 then
                    indentation = ""
                else
                    indentation = string.rep(" ", indent_level * 4) -- 4 * indent_level number of leading spaces
                end

                if key_str then -- If we are a non-integer-keyed table, use key = value format
                    table.insert(result, indentation .. key_str .. " = " .. value_str)
                else -- Else just place values directly
                    table.insert(result, indentation .. value_str)
                end
            end
        end

        local serialized_table
        -- Closing indent 1 level less than what it was called with
        local closing_indent = string.rep(" ", math.max(0, (indent_level - 1) * 4))

        if indent_level == 0 then -- single line version
            serialized_table = "{" .. table.concat(result, ", ") .. "}"
            result_type = "List"
        else -- indented version
            serialized_table = "{\n" .. table.concat(result, ",\n") .. "\n" .. closing_indent .. "}"
        end


        if result_type == "List" or #result == 0 then
            serialized_table = "L" .. serialized_table -- If all integer keys, prepend L to the braces
        end
        return serialized_table
    end
end

function serializer_util.serialize_args(...)
    local args = {...}

    local serialized_args = {}
    for i = 1, table.maxn(args) do
        table.insert(serialized_args, serializer_util.serialize(args[i], 0))
    end
    return table.concat(serialized_args, ", ")
end

return serializer_util