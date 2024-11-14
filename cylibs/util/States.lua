local Event = require('cylibs/events/Luvent')

require('sets')

---------------------------
-- Utility class for representing player states. Requiring this in your addon will automatically create a global
-- State table and addon commands to retrieve and manipulate state values.
-- @class module
-- @name States

_libs = _libs or {}

---- Global table of player states. You can extend the list of States in your addon file
---- (e.g. state.AutoTargetMode = M{['description'] = 'AutoTargetMode', 'Auto', 'Off'}
-- @table State
state = {}

local modes_locked = false
local modes_locked_reason
local modes_whitelist = S{}
local state_changed = Event.newEvent()

function on_state_changed()
    return state_changed
end

function set_modes_locked(locked, reason, whitelist)
    modes_locked = locked
    modes_locked_reason = reason
    if locked then
        modes_whitelist = S((whitelist or L{}):map(function(mode) return mode:lower() end))
    else
        modes_whitelist = S{}
    end
end

function is_modes_locked()
    return modes_locked
end

function handle_cycle(field)
    if modes_locked and not modes_whitelist:contains(field:lower()) then
        addon_message(123, modes_locked_reason or "You cannot changes modes at this time.")
        return
    end
    if field == nil then
        addon_message(123,'Cycle parameter failure: field not specified.')
        return
    end

    local state_var = get_state(field)

    if state_var then
        local oldVal = state_var.value
        state_var:cycle()

        local newVal = state_var.value

        local descrip = state_var.description or field

        addon_message(122,field..' is now '..state_var.current..'.')
        --handle_update({'auto'})
    else
        addon_message(123,'Cycle: Unknown field ['..field..']')
    end
end

-- Get the state var that matches the requested name.
-- Only returns mode vars.
function get_state(name)
    if state[name] then
        return state[name]._class == 'mode' and state[name] or nil
    else
        local l_name = name:lower()
        for key,var in pairs(state) do
            if key:lower() == l_name then
                return var._class == 'mode' and var or nil
            end
        end
    end
end

function get_state_name(l_name)
    for key,var in pairs(state) do
        if key:lower() == l_name then
            return key
        end
    end
    return l_name
end

function handle_set(field, value)
    if modes_locked and not modes_whitelist:contains(field:lower()) then
        addon_message(123, modes_locked_reason or "You cannot changes modes at this time.")
        return
    end
    if field == nil then
        add_to_chat(123,'Set parameter failure: field not specified.')
        return
    end
    if value == nil then
        add_to_chat(123,'Set parameter failure: value not specified.')
        return
    end

    local state_var = get_state(field)

    if state_var then
        local oldVal = state_var.value
        state_var:set(value)
        local newVal = state_var.value

        if newVal ~= oldVal then
            on_state_changed():trigger(field, newVal)
        end

        local descrip = state_var.description or cmdParams[1]
        if state_change then
            state_change(descrip, newVal, oldVal)
        end

        local msg = field..' is now '..state_var.current
        if state_var == state.DefenseMode and newVal ~= 'None' then
            msg = msg .. ' (' .. state[newVal .. 'DefenseMode'].current .. ')'
        end
        msg = msg .. '.'

        addon_message(122, msg)
        --handle_update({'auto'})
    else
        addon_message(123,'Set: Unknown field ['..field..']')
    end

    -- handle string states: CombatForm, CombatWeapon, etc
end

function addon_message(color,str)
    windower.add_to_chat(color, _addon.name..': '..str)
end