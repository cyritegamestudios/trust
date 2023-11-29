local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SkillchainTrustCommands = setmetatable({}, {__index = TrustCommands })
SkillchainTrustCommands.__index = SkillchainTrustCommands
SkillchainTrustCommands.__class = "SkillchainTrustCommands"

function SkillchainTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), SkillchainTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    -- AutoSkillchainMode
    self:add_command('auto', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Auto', 'Off')  end, 'Automatically make skillchains')
    self:add_command('spam', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Spam', 'Off')  end, 'Spam the same weapon skill')
    self:add_command('cleave', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Cleave', 'Off')  end, 'Cleave monsters')

    -- SkillchainPartnerMode
    self:add_command('partner', function(_) return self:handle_toggle_mode('SkillchainPartnerMode', 'Auto', 'Off')  end, 'Make skillchains with party members')
    self:add_command('open', function(_) return self:handle_toggle_mode('SkillchainPartnerMode', 'Open', 'Off')  end, 'Only open skillchains')
    self:add_command('close', function(_) return self:handle_toggle_mode('SkillchainPartnerMode', 'Close', 'Off')  end, 'Only close skillchains')

    -- SkillchainPriorityMode
    self:add_command('prefer', function(_) return self:handle_toggle_mode('SkillchainPriorityMode', 'Prefer', 'Off')  end, 'Prioritize using weapon skills in preferws')
    self:add_command('strict', function(_) return self:handle_toggle_mode('SkillchainPriorityMode', 'Strict', 'Off')  end, 'Only use weapon skills in preferws')

    -- AutoAftermathMode
    self:add_command('am', function(_) return self:handle_toggle_mode('AutoAftermathMode', 'Auto', 'Off')  end, 'Prioritize maintaining aftermath on mythic weapons')

    return self
end

function SkillchainTrustCommands:get_command_name()
    return 'sc'
end

-- // trust sc [auto, spam, cleave, partner, open, close, prefer, strict, am]
function SkillchainTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

return SkillchainTrustCommands