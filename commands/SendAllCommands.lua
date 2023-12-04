local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SendAllTrustCommands = setmetatable({}, {__index = TrustCommands })
SendAllTrustCommands.__index = SendAllTrustCommands
SendAllTrustCommands.__class = "SendAllTrustCommands"

function SendAllTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), SendAllTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_send_command, 'Send a command to all players, // trust sendall command_name')

    return self
end

function SendAllTrustCommands:get_command_name()
    return 'sendall'
end

-- // trust sendall command
function SendAllTrustCommands:handle_send_command(...)
    local success = true
    local message

    local windower_command = ''
    for _, token in ipairs(arg) do
        if token == 'me' then
            token = windower.ffxi.get_player().name
        end
        windower_command = windower_command..token..' '
    end
    if #windower_command > 0 then
        if L{'All', 'Send'}:contains(state.IpcMode.value) then
            IpcRelay.shared():send_message(CommandMessage.new(windower_command))
            success = true
            message = 'Executing command: '..windower_command..' on all players'
        else
            success = false
            message = 'IpcMode must be set to All or Send to use this command'
        end
    end

    return success, message
end

return SendAllTrustCommands