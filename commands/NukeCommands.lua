local TrustCommands = require('cylibs/trust/commands/trust_commands')
local NukeTrustCommands = setmetatable({}, {__index = TrustCommands })
NukeTrustCommands.__index = NukeTrustCommands
NukeTrustCommands.__class = "NukeTrustCommands"

function NukeTrustCommands.new(trust, trust_settings, action_queue)
    local self = setmetatable(TrustCommands.new(), NukeTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.action_queue = action_queue

    -- AutoNukeMode
    self:add_command('off', function(_) return self:handle_set_mode('AutoNukeMode', 'Off')  end, 'Disable free nuking')
    self:add_command('earth', function(_) return self:handle_set_mode('AutoNukeMode', 'Earth')  end, 'Free nuke with earth spells')
    self:add_command('lightning', function(_) return self:handle_set_mode('AutoNukeMode', 'Lightning')  end, 'Free nuke with lightning spells')
    self:add_command('water', function(_) return self:handle_set_mode('AutoNukeMode', 'Water')  end, 'Free nuke with water spells')
    self:add_command('fire', function(_) return self:handle_set_mode('AutoNukeMode', 'Fire')  end, 'Free nuke with fire spells')
    self:add_command('ice', function(_) return self:handle_set_mode('AutoNukeMode', 'Ice')  end, 'Free nuke with ice spells')
    self:add_command('wind', function(_) return self:handle_set_mode('AutoNukeMode', 'Wind')  end, 'Free nuke with wind spells')
    self:add_command('light', function(_) return self:handle_set_mode('AutoNukeMode', 'Light')  end, 'Free nuke with light spells')
    self:add_command('dark', function(_) return self:handle_set_mode('AutoNukeMode', 'Dark')  end, 'Free nuke with dark spells')
    self:add_command('cleave', function(_) return self:handle_set_mode('AutoNukeMode', 'Cleave')  end, 'Cleave enemies with AOE spells')

    return self
end

function NukeTrustCommands:get_command_name()
    return 'nuke'
end

function NukeTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

-- // trust nuke [auto, earth, lightning, water, fire, ice, wind, light, dark, cleave]
function NukeTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
    local success = true
    local message

    local mode_var = get_state(mode_var_name)
    if mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end

    return success, message
end

function NukeTrustCommands:handle_set_mode(mode_name, mode_value)
    local success = true
    local message

    handle_set(mode_name, mode_value)

    return success, message
end

return NukeTrustCommands
