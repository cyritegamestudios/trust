local TrustCommands = require('cylibs/trust/commands/trust_commands')
local GeneralTrustCommands = setmetatable({}, {__index = TrustCommands })
GeneralTrustCommands.__index = GeneralTrustCommands
GeneralTrustCommands.__class = "GeneralTrustCommands"

function GeneralTrustCommands.new(trust, action_queue, addon_enabled, trust_mode_settings, main_trust_settings, sub_trust_settings)
    local self = setmetatable(TrustCommands.new(), GeneralTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.addon_enabled = addon_enabled
    self.trust_mode_settings = trust_mode_settings
    self.main_trust_settings = main_trust_settings
    self.sub_trust_settings = sub_trust_settings
    self.hud = hud

    -- State
    self:add_command('start', self.handle_start, 'Start Trust')
    self:add_command('stop', self.handle_stop, 'Stop Trust')
    self:add_command('toggle', self.handle_toggle, 'Toggle Trust On and Off')
    self:add_command('reload', self.handle_reload, 'Reload job settings files')
    self:add_command('status', self.handle_status, 'View Trust status')

    -- Modes
    self:add_command('set', self.handle_set_mode, 'Set a mode to a given value, // trust set mode_name mode_value')
    self:add_command('cycle', self.handle_cycle_mode, 'Cycle the value of a mode, // trust cycle mode_name')
    self:add_command('load', self.handle_load_set, 'Load a mode set, // trust load mode_set_name')
    self:add_command('save', self.handle_save_set, 'Save changes to the current mode set or new set, // trust save mode_set_name (optional)')

    return self
end

function GeneralTrustCommands:get_command_name()
    return 'default'
end

function GeneralTrustCommands:get_all_commands()
    local result = L{}
    for command_name, command in pairs(self.commands) do
        result:append('// trust '..command_name)
    end
    return result
end

-- // trust status
function GeneralTrustCommands:handle_status()
    local success = true
    local message

    local statuses = L{}
    for key,var in pairs(state) do
        statuses:append(key..': '..var.value)
    end
    statuses:sort()

    for status in statuses:it() do
        addon_message(207, status)
    end

    if player.party:get_assist_target() then
        addon_message(209, 'Assisting '..player.party:get_assist_target():get_name())
    end

    return success, message
end

-- // trust start
function GeneralTrustCommands:handle_start(_)
    local success = true
    local message = "Trust started"

    self.addon_enabled:setValue(true)

    return success, message
end

-- // trust stop
function GeneralTrustCommands:handle_stop(_)
    local success = true
    local message = "Trust stopped"

    self.addon_enabled:setValue(false)

    return success, message
end

-- // trust toggle
function GeneralTrustCommands:handle_toggle(_)
    local success = true
    local message = "Trust stopped"

    if self.addon_enabled:getValue() then
        success, message = self:handle_stop(_)
    else
        success, message = self:handle_start(_)
    end

    return success, message
end

-- // trust reload
function GeneralTrustCommands:handle_reload(_)
    local success = true
    local message

    self.main_trust_settings:loadSettings()
    self.sub_trust_settings:loadSettings()

    return success, message
end

-- // trust set mode_name mode_value
function GeneralTrustCommands:handle_set_mode(_, mode_name, mode_value)
    local success = true
    local message

    handle_set(mode_name, mode_value)

    return success, message
end

-- // trust cycle mode_name
function GeneralTrustCommands:handle_cycle_mode(_, mode_name)
    local success = true
    local message

    handle_cycle(mode_name)

    return success, message
end

-- // trust load mode_set_name
function GeneralTrustCommands:handle_load_set(_, mode_set_name)
    local success
    local message

    if not mode_set_name then
        success = false
        message = "Invalid mode set name"
    else
        success = true

        state.TrustMode:set(mode_set_name)
    end

    return success, message
end

-- // trust save or // trust save mode_set_name
function GeneralTrustCommands:handle_save_set(_, mode_set_name)
    local success = true
    local message

    trust_mode_settings:saveSettings(mode_set_name or state.TrustMode.value)

    return success, message
end


return GeneralTrustCommands