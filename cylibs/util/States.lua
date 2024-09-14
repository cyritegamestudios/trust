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

function set_modes_locked(locked, reason)
    modes_locked = locked
    modes_locked_reason = reason
end

function is_modes_locked()
    return modes_locked
end

function handle_cycle(field)
    if modes_locked then
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

function handle_set(field, value)
    if modes_locked then
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

---- A list of addon commands to manipulate State values. Syntax: // st field (see below).
-- @table Commands
-- @field cycle Cycles through the values of a State. Usage: // addon_name cycle state_name (e.g. // st cycle AutoTargetMode)
-- @field set Sets the value a State. Usage: // addon_name set state_name value (e.g. // st set AutoTargetMode Off)
local commands = {}
commands['cycle'] = handle_cycle
commands['set'] = handle_set

local function addon_command(cmd, ...)
    local cmd = cmd or 'help'

    if commands[cmd] then
        local msg = commands[cmd](unpack({...}))
        if msg then
            error(msg)
        end
    end
end

windower.register_event('addon command', addon_command)