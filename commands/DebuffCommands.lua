local TrustCommands = require('cylibs/trust/commands/trust_commands')
local DebuffCommands = setmetatable({}, {__index = TrustCommands })
DebuffCommands.__index = DebuffCommands
DebuffCommands.__class = "DebuffCommands"

function DebuffCommands.new()
    local self = setmetatable(TrustCommands.new(), DebuffCommands)

    self:add_command('default', function(_) return self:handle_toggle_mode('AutoDebuffMode', 'Auto', 'Off')  end, 'Toggle debuffs')
    self:add_command('auto', function(_) return self:handle_set_mode('AutoDebuffMode', 'Auto')  end, 'Enable debuffs')
    self:add_command('off', function(_) return self:handle_set_mode('AutoDebuffMode', 'Off')  end, 'Disable debuffs')

    return self
end

function DebuffCommands:get_command_name()
    return 'debuff'
end

function DebuffCommands:get_localized_command_name()
    return 'Debuff'
end

return DebuffCommands
