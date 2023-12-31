local TrustRemoteCommands = {}
TrustRemoteCommands.__index = TrustRemoteCommands

local native_commands_whitelist = S{
    'refa all',
    'warp',
    'pcmd leave',
}

function TrustRemoteCommands.new(whitelist, commands)
    local self = setmetatable({
        whitelist = whitelist;
        commands = commands;
        action_events = {}
    }, TrustRemoteCommands)

    self:on_init()

    return self
end

function TrustRemoteCommands:on_init()
    self.action_events.chat_message = windower.register_event('chat message', function(message, sender, mode, gm)
        if not gm and self.whitelist:contains(sender) then
            local args = string.split(message, ' ')
            if args[1] == 'trust' then
                self:handle_command(sender, args:slice(2))
            elseif native_commands_whitelist:contains(message) then
                self:handle_native_command(sender, message)
            end
        end
    end)

    for name in self.whitelist:it() do
        native_commands_whitelist:add('pcmd add '..name)
        native_commands_whitelist:add('pcmd kick '..name)
        native_commands_whitelist:add('pcmd leader '..name)
    end
end

function TrustRemoteCommands:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function TrustRemoteCommands:handle_command(sender, args)
    local cmd = args[1]
    if cmd then
        local params = ''
        for _,v in ipairs(args) do
            params = params..' '..tostring(v)
        end
        if self.commands:contains(cmd) or L{'cycle', 'set', 'assist', 'follow'}:contains(cmd) then
            windower.send_command('input // trust '..params)

            addon_message(209, 'Executing remote command from '..sender..': trust'..params)
        else
            error('Unknown remote command from '..sender..': trust'..params)
        end
    end
end

function TrustRemoteCommands:handle_native_command(sender, command)
    windower.chat.input('/'..command)

    addon_message(209, 'Executing remote command from '..sender..': '..command)
end

-- Custom commands

function TrustRemoteCommands:handle_dismiss_trusts()
    local cmd = args[1]
    if cmd then
        local params = ''
        for _,v in ipairs(args) do
            params = params..' '..tostring(v)
        end
        if self.commands:contains(cmd) then
            windower.send_command('input // trust '..params)

            addon_message(209, 'Executing remote command from '..sender..': trust'..params)
        else
            error('Unknown remote command from '..sender..': trust'..params)
        end
    end
end

return TrustRemoteCommands



