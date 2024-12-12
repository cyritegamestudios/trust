local CommandMessage = require('cylibs/messages/command_message')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local WarpCommands = setmetatable({}, {__index = TrustCommands })
WarpCommands.__index = WarpCommands
WarpCommands.__class = "WarpCommands"

function WarpCommands.new(action_queue)
    local self = setmetatable(TrustCommands.new(), WarpCommands)

    self.action_queue = action_queue

    self:add_command('default', self.handle_warp, 'Uses /warp')
    self:add_command('all', self.handle_warp_all, 'Uses /warp on all party members')

    return self
end

function WarpCommands:get_command_name()
    return 'warp'
end

-- // trust warp include_party
function WarpCommands:handle_warp(include_party)
    local success = true
    local message

    if include_party then
        message = "Using /warp on all party members"
        IpcRelay.shared():send_message(CommandMessage.new('/warp'))
    else
        message = "Using /warp"
    end
    self.action_queue:push_action(CommandAction.new(0, 0, 0, '/warp'), true)

    return success, message
end

-- // trust warp all
function WarpCommands:handle_warp_all()
    return self:handle_warp(true)
end

return WarpCommands