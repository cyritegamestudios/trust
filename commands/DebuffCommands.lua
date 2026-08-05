local gambit_commands = require('cylibs/trust/commands/gambit_commands')
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local DebuffCommands = setmetatable({}, {__index = TrustCommands })
DebuffCommands.__index = DebuffCommands
DebuffCommands.__class = "DebuffCommands"

function DebuffCommands.new(trust, trust_settings)
    local self = setmetatable(TrustCommands.new(), DebuffCommands)

    self.trust = trust
    self.trust_settings = trust_settings

    self:add_command('default', function(_) return self:handle_toggle_mode('AutoDebuffMode', 'Auto', 'Off')  end, 'Toggle debuffs')
    self:add_command('auto', function(_) return self:handle_set_mode('AutoDebuffMode', 'Auto')  end, 'Enable debuffs')
    self:add_command('off', function(_) return self:handle_set_mode('AutoDebuffMode', 'Off')  end, 'Disable debuffs')

    gambit_commands.install(self, {
        noun = 'debuff',
        trust = trust,
        default_target = 'enemy',
        gambits = function(commands)
            local settings = commands.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
            return settings and settings.DebuffSettings and settings.DebuffSettings.Gambits
        end,
        save = function(commands) commands.trust_settings:saveSettings(true) end,
    })

    return self
end

function DebuffCommands:get_command_name()
    return 'debuff'
end

function DebuffCommands:get_localized_command_name()
    return 'Debuff'
end

return DebuffCommands
