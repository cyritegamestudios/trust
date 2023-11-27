local TrustCommands = require('cylibs/trust/commands/trust_commands')
local AttackTrustCommands = setmetatable({}, {__index = TrustCommands })
AttackTrustCommands.__index = AttackTrustCommands
AttackTrustCommands.__class = "AttackTrustCommands"

function AttackTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), AttackTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    -- AutoEngageMode
    self:add_command('engage', function(_) return self:handle_toggle_mode('AutoEngageMode', 'Always', 'Off')  end, 'Automatically engage mobs party is fighting')
    self:add_command('mirror', function(_) return self:handle_toggle_mode('AutoEngageMode', 'Mirror', 'Off')  end, 'Automatically engage only if assist target is fighting')
    self:add_command('assist', function(_) return self:handle_toggle_mode('AutoEngageMode', 'Assist', 'Off')  end, 'Automatically lock onto the battle target but don\'t engage')

    return self
end

function AttackTrustCommands:get_command_name()
    return 'attack'
end

-- // trust attack [engage, mirror, assist]
function AttackTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

return AttackTrustCommands