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
    self:add_command('party', function(_) return self:handle_toggle_mode('AutoPullMode', 'Party', 'Off')  end, 'Automatically pull whatever monster the party is fighting')
    self:add_command('all', function(_) return self:handle_toggle_mode('AutoPullMode', 'All', 'Off')  end, 'Automatically pull whatever monsters are nearby')
    self:add_command('camp', self.handle_camp, 'Automatically return to camp after battle')

    return self
end

function PullTrustCommands:get_command_name()
    return 'pull'
end

function PullTrustCommands:get_puller()
    return self.trust:role_with_type("puller")
end

-- // trust pull camp
function PullTrustCommands:handle_camp(_)
    local success
    local message

    if state.AutoCampMode.value == 'Off' then
        success = false
        message = "AutoCampMode must be set to Auto"
    else
        self:get_puller():set_camp_position(ffxi_util.get_mob_position(windower.ffxi.get_player().name))

        success = true
        message = "Return to the current position after battle"
    end

    return success, message
end

return PullTrustCommands