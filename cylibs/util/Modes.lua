local Event = require('cylibs/events/Luvent')

---------------------------
-- Library allowing use of specially-designed tables for tracking
-- certain types of Modes and State.
-- @class module
-- @name Modes

_meta = _meta or {}
_meta.M = {}
_meta.M.__class = 'mode'
_meta.M.__methods = {}

-- Default constructor for mode tables
-- M{'a', 'b', etc, ['description']='a'} -- defines a mode list, description 'a'
-- M('a', 'b', etc) -- defines a mode list, no description
-- M('a') -- defines a mode list, default 'a'
-- M{['description']='a'} -- defines a mode list, default 'Normal', description 'a'
-- M{} -- defines a mode list, default 'Normal', no description
-- M(false) -- defines a mode boolean, default false, no description
-- M(true) -- defines a mode boolean, default true, no description
-- M(false, 'a') -- defines a mode boolean, default false, description 'a'
-- M(true, 'a') -- defines a mode boolean, default true, description 'a'
-- M() -- defines a mode boolean, default false, no description
function M(t, ...)
    local m = {}
    m._track = {}
    m._track._class = 'mode'
    -- If we're passed a list of strings (that is, the first element is a string),
    -- convert them to a table
    local args = {...}
    if type(t) == 'string' then
        t = {[1] = t}
        
        for ind, val in ipairs(args) do
            t[ind+1] = val
        end
    end

    -- Construct the table that we'll be adding the metadata to
    
    -- If we have a table of values, it's either a list or a string
    if type(t) == 'table' then
        -- Save the description, if provided
        if t['description'] then
            m._track._description = t['description']
        end

        -- If we were given an explicit 'string' field, construct a string mode class.
        if t.string and type(t.string) == 'string' then
            m._track._type = 'string'
            m._track._count = 1
            m._track._default = 'defaultstring'

            if t.string then
                m['string'] = t.string
                m['defaultstring'] = t.string
            end
        -- Otherwise put together a standard list mode class.
        else
            m._track._type = 'list'
            m._track._invert = {}
            m._track._count = 0
            m._track._default = 1

            -- Only copy numerically indexed values
            local t_copy = T(t):flatten()
            for ind, val in ipairs(t_copy) do
                m[ind] = val
                m._track._invert[val] = ind
                m._track._count = ind
            end
            
            if m._track._count == 0 then
                m[1] = 'Normal'
                m._track._invert['Normal'] = 1
                m._track._count = 1
            end
        end
    -- If the first argument is a bool, construct a boolean mode class.
    elseif type(t) == 'boolean' or t == nil then
        m._track._type = 'boolean'
        m._track._count = 2
        m._track._default = t or false
        m._track._description = args[1]
        -- Text lookups for bool values
        m[true] = 'on'
        m[false] = 'off'
    else
        -- Construction failure
        error("Unable to construct a mode table with the provided parameters.", 2)
    end

    -- Initialize current value to the default.
    m._track._current = m._track._default

    m._state_change = Event.newEvent()

    m._value_descriptions = {}

    return setmetatable(m, _meta.M)
end

--------------------------------------------------------------------------
-- Metamethods
-- Functions that will be used as metamethods for the class
--------------------------------------------------------------------------

_meta.M.__index = function(m, k)
    if type(k) == 'string' then
        local lk = k:lower()
        if lk == 'current' then
            return m[m._track._current]
        elseif lk == 'value' then
            if m._track._type == 'boolean' then
                return m._track._current
            else
                return m[m._track._current]
            end
        elseif lk == 'has_value' then
            return _meta.M.__methods.f_has_value(m)
        elseif lk == 'default' then
            if m._track._type == 'boolean' then
                return m._track._default
            else
                return m[m._track._default]
            end
        elseif lk == 'description' then
            return m._track._description
        elseif lk == 'index' then
            return m._track._current
        elseif m._track[lk] then
            return m._track[lk]
        elseif m._track['_'..lk] then
            return m._track['_'..lk]
        else
            return _meta.M.__methods[lk]
        end
    end
end

-------
-- Tostring handler for printing out the table and its current state.
-- @tparam Mode m Self
-- @treturn string Human readable representation of the Mode in its current state
_meta.M.__tostring = function(m)
    local res = ''
    if m._track._description then
        res = res .. m._track._description .. ': '
    end

    if m._track._type == 'list' then
        res = res .. '{'
        for k,v in ipairs(m) do
            res = res..tostring(v)
            if m[k+1] ~= nil then
                res = res..', '
            end
        end
        res = res..'}' 
    elseif m._track._type == 'string' then
        res = res .. 'String'
    else
        res = res .. 'Boolean'
    end
    
    res = res .. ' ('..tostring(m.Current).. ')'
    
    -- Debug addition
    --res = res .. ' [' .. m._track._type .. '/' .. tostring(m._track._current) .. ']'

    return res
end

-- Length handler for the # value lookup.
_meta.M.__len = function(m)
    return m._track._count
end

_meta.M.__methods['describe'] = function(m, str)
    if type(str) == 'string' then
        m._track._description = str
    else
        error("Invalid argument type: " .. type(str), 2)
    end
end

_meta.M.__methods['options'] = function(m, ...)
    if m._track._type ~= 'list' then
        error("Can only revise the options list for a list mode class.", 2)
    end

    local options = {...}
    -- Always include a default option if nothing else is given.
    if #options == 0 then
        --options = {'Normal'}
        local result = L{}
        for key = 1, m._track._count do
            result:append(m[key])
        end
        return result
    end

    -- Zero-out existing values and clear the tracked inverted list
    -- and member count.    
    for key,val in ipairs(m) do
        m[key] = nil
    end
    m._track._invert = {}
    m._track._count = 0

    -- Insert in new data.
    for key,val in ipairs(options) do
        m[key] = val
        m._track._invert[val] = key
        m._track._count = key
    end
    
    m._track._current = m._track._default
end

_meta.M.__methods['contains'] = function(m, str)
    if m._track._invert then
        if type(str) == 'string' then
            return (m._track._invert[str] ~= nil)
        else
            error("Invalid argument type: " .. type(str), 2)
        end
    else
        error("Cannot test for containment on a " .. m._track._type .. " mode class.", 2)
    end
end

_meta.M.__methods['cycle'] = function(m)
    local old_value = m.Current
    if m._track._type == 'list' then
        m._track._current = (m._track._current % m._track._count) + 1
    elseif m._track._type == 'boolean' then
        m:toggle()
    end

    m:on_state_change():trigger(m, m.Current, old_value)

    return m.Current
end

-- Cycle backwards through the list
_meta.M.__methods['cycleback'] = function(m)
    local old_value = m.Current
    if m._track._type == 'list' then
        m._track._current = m._track._current - 1
        if  m._track._current < 1 then
            m._track._current = m._track._count
        end
    elseif m._track._type == 'boolean' then
        m:toggle()
    end

    m:on_state_change():trigger(m, m.Current, old_value)

    return m.Current
end

-- Toggle a boolean value
_meta.M.__methods['toggle'] = function(m)
    if m._track._type == 'boolean' then
        m._track._current = not m._track._current
    else
        error("Can only toggle a boolean mode.", 2)
    end

    return m.Current
end


-- Set the current value
_meta.M.__methods['set'] = function(m, val)
    local old_value = m.Current
    if m._track._type == 'boolean' then
        if val == nil then
            m._track._current = true
        elseif type(val) == 'boolean' then
            m._track._current = val
        elseif type(val) == 'string' then
            val = val:lower()
            if val == 'on' or val == 'true' then
                m._track._current = true
            elseif val == 'off' or val == 'false' then
                m._track._current = false
            else
                error("Unrecognized value: "..tostring(val), 2)
            end
        else
            error("Unrecognized value type: "..type(val), 2)
        end
    elseif m._track._type == 'list' then
        if not val then
            error("List variable cannot be set to nil.", 2)
        end
        if m._track._invert[val] then
            m._track._current = m._track._invert[val]
        else
            local found = false
            for v, ind in pairs(m._track._invert) do
                if val:lower() == v:lower() then
                    m._track._current = ind
                    found = true
                    break
                end
            end
            
            if not found then
                error("Unknown mode value: " .. tostring(val), 2)
            end
        end
    elseif m._track._type == 'string' then
        if type(val) == 'string' then
            m._track._current = 'string'
            m.string = val
        else
            error("Unrecognized value type: "..type(val), 2)
        end
    end

    m:on_state_change():trigger(m, m.Current, old_value)

    return m.Current
end


-- Forces a boolean mode to false, or a string to an empty string.
_meta.M.__methods['unset'] = function(m)
    if m._track._type == 'boolean' then
        m._track._current = false
    elseif m._track._type == 'string' then
        m._track._current = 'string'
        m.string = ''
    else
        error("Cannot unset a list mode class.", 2)
    end

    return m.Current
end


-- Reset to the default value
_meta.M.__methods['reset'] = function(m)
    local old_value = m.Current
    m._track._current = m._track._default

    m:on_state_change():trigger(m, m.Current, old_value)

    return m.Current
end


-- Check to be sure that the mode var has a valid (for its type) value.
-- String vars must be non-empty.
-- List vars must not be empty strings, or the word 'none'.
-- Boolean are always considered valid (can only be true or false).
_meta.M.__methods['f_has_value'] = function(m)
    local cur = m.value
    if m._track._type == 'string' then
        if cur and cur ~= '' then
            return true
        else
            return false
        end
    elseif m._track._type == 'boolean' then
        return true
    else
        if not cur or cur == '' or cur:lower() == 'none' then
            return false
        else
            return true
        end
    end
end

_meta.M.__methods['on_state_change'] = function(m)
    return m._state_change
end

_meta.M.__methods['set_description'] = function(m, value, text)
    m._value_descriptions[value] = text
end

_meta.M.__methods['get_description'] = function(m, value)
    if value == nil then
        return m._track._description
    else
        return m._value_descriptions[value]
    end
end

