local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MagicBurstTrustCommands = setmetatable({}, {__index = TrustCommands })
MagicBurstTrustCommands.__index = MagicBurstTrustCommands
MagicBurstTrustCommands.__class = "MagicBurstTrustCommands"

function MagicBurstTrustCommands.new(trust, trust_settings, action_queue)
    local self = setmetatable(TrustCommands.new(), MagicBurstTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.action_queue = action_queue

    -- AutoMagicBurstMode
    self:add_command('auto', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Auto', 'Off')  end, 'Magic burst with spells of any element')
    self:add_command('earth', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Earth', 'Off')  end, 'Magic burst with earth spells')
    self:add_command('lightning', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Lightning', 'Off')  end, 'Magic burst with lightning spells')
    self:add_command('water', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Water', 'Off')  end, 'Magic burst with water spells')
    self:add_command('fire', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Fire', 'Off')  end, 'Magic burst with fire spells')
    self:add_command('ice', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Ice', 'Off')  end, 'Magic burst with ice spells')
    self:add_command('wind', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Wind', 'Off')  end, 'Magic burst with wind spells')
    self:add_command('light', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Light', 'Off')  end, 'Magic burst with light spells')
    self:add_command('dark', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Dark', 'Off')  end, 'Magic burst with dark spells')

    return self
end

function MagicBurstTrustCommands:get_command_name()
    return 'mb'
end

function MagicBurstTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

-- // trust mb [auto, earth, lightning, water, fire, ice, wind, light, dark]
function MagicBurstTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

return MagicBurstTrustCommands
