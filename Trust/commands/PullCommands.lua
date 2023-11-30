local TrustCommands = require('cylibs/trust/commands/trust_commands')
local PullTrustCommands = setmetatable({}, {__index = TrustCommands })
PullTrustCommands.__index = PullTrustCommands
PullTrustCommands.__class = "PullTrustCommands"

function PullTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), PullTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    -- AutoPullMode
    self:add_command('auto', function(_) return self:handle_toggle_mode('AutoPullMode', 'Auto', 'Off')  end, 'Automatically pull mobs for the party')
    self:add_command('multi', function(_) return self:handle_toggle_mode('AutoPullMode', 'Multi', 'Off')  end, 'Automatically pull a monster even if the party is already fighting')
    self:add_command('target', function(_) return self:handle_toggle_mode('AutoPullMode', 'Target', 'Off')  end, 'Automatically pull whatever monster is currently targeted')

    return self
end

function PullTrustCommands:get_command_name()
    return 'pull'
end

-- // trust pull [auto, multi, target]
function PullTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

return PullTrustCommands