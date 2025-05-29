local Whitelist = require('settings/settings').Whitelist

local TrustRemoteCommands = {}
TrustRemoteCommands.__index = TrustRemoteCommands

local native_commands_whitelist = L{
    'refa all',
    'warp',
    'pcmd leave',
    'pcmd add',
    'pcmd kick',
    'pcmd leader',
    'acmd add',
    'acmd leave',
    'acmd kick',
    'acmd breakup',
    'acmd leader',
    'attack',
    'attackoff',
    'jobability',
    'magic',
    'weaponskill',
}

function TrustRemoteCommands.new()
    local self = setmetatable({
        events = {};
    }, TrustRemoteCommands)

    self:on_init()

    return self
end

function TrustRemoteCommands:destroy()
    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function TrustRemoteCommands:on_init()
    self.events.chat_message = windower.register_event('chat message', function(message, sender, mode, gm)
        if mode == 3 and not gm and self:get_whitelist():contains(sender) then
            local args = string.split(message, ' ')
            if args[1] == 'trust' then
                windower.send_command('input // '..message)
            else
                for _, prefix in ipairs(native_commands_whitelist) do
                    if message:match("^" .. prefix) then
                        self:handle_native_command(sender, message)
                        return
                    end
                end
            end
        end
    end)
end

function TrustRemoteCommands:get_whitelist()
    return Whitelist:all():map(function(user) return user.id end)
end

function TrustRemoteCommands:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function TrustRemoteCommands:handle_native_command(sender, command)
    windower.chat.input('/'..command)

    addon_message(209, 'Executing remote command from '..sender..': '..command)
end

return TrustRemoteCommands



