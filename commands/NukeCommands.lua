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
    self:add_command('earth', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Earth', 'Off')  end, 'Free nuke with earth spells')
    self:add_command('lightning', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Lightning', 'Off')  end, 'Free nuke with lightning spells')
    self:add_command('water', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Water', 'Off')  end, 'Free nuke with water spells')
    self:add_command('fire', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Fire', 'Off')  end, 'Free nuke with fire spells')
    self:add_command('ice', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Ice', 'Off')  end, 'Free nuke with ice spells')
    self:add_command('wind', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Wind', 'Off')  end, 'Free nuke with wind spells')
    self:add_command('light', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Light', 'Off')  end, 'Free nuke with light spells')
    self:add_command('dark', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Dark', 'Off')  end, 'Free nuke with dark spells')
    self:add_command('cleave', function(_) return self:handle_toggle_mode('AutoNukeMode', 'Cleave', 'Off')  end, 'Cleave enemies with AOE spells')

    return self
end

function NukeTrustCommands:get_command_name()
    return 'nuke'
end

function NukeTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

-- // trust mb [auto, earth, lightning, water, fire, ice, wind, light, dark]
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

return NukeTrustCommands
