local gambit_commands = require('cylibs/trust/commands/gambit_commands')
local GambitTarget = require('cylibs/gambits/gambit_target')
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local BuffCommands = setmetatable({}, {__index = TrustCommands })
BuffCommands.__index = BuffCommands
BuffCommands.__class = "BuffCommands"

function BuffCommands.new(trust, trust_settings)
    local self = setmetatable(TrustCommands.new(), BuffCommands)

    self.trust = trust
    self.trust_settings = trust_settings

    -- AutoBuffMode
    self:add_command('default', function(_) return self:handle_toggle_mode('AutoBuffMode', 'Auto', 'Off')  end, 'Toggle buffs on self and party')
    self:add_command('auto', self.handle_enable_buffs, 'Enable buffs on self and party')
    self:add_command('off', self.handle_disable_buffs, 'Disable buffs on self and party')

    gambit_commands.register(self, {
        noun = self:get_command_name(),
        trust = trust,
        default_target = GambitTarget.TargetType.Self,
        targets = L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally },
        gambits = function(commands)
            local settings = commands:get_settings()
            return settings and settings.BuffSettings and settings.BuffSettings.Gambits
        end,
        save = function(commands) commands.trust_settings:saveSettings(true) end,
    })

    return self
end

function BuffCommands:get_command_name()
    return 'buff'
end

function BuffCommands:get_localized_command_name()
    return 'Buff'
end

function BuffCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

-- // trust buff
function BuffCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

-- // trust buff auto
function BuffCommands:handle_enable_buffs(_)
    handle_set('AutoBuffMode', 'Auto')

    return true, nil
end

-- // trust buff off
function BuffCommands:handle_disable_buffs(_)
    handle_set('AutoBuffMode', 'Off')

    return true, nil
end

return BuffCommands
