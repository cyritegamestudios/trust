local DisposeBag = require('cylibs/events/dispose_bag')

local TrustRemoteCommands = {}
TrustRemoteCommands.__index = TrustRemoteCommands

local default_native_commands = L{
    'refa all',
    'warp',
    'pcmd leave',
    'pcmd add',
    'pcmd kick',
    'pcmd leader',
}

local native_commands_whitelist = L{
}

function TrustRemoteCommands.new(addonSettings)
    local self = setmetatable({
        addonSettings = addonSettings;
        action_events = {};
        disposeBag = DisposeBag.new()
    }, TrustRemoteCommands)

    self:on_init()

    return self
end

function TrustRemoteCommands:destroy()
    self.disposeBag:destroy()
end

function TrustRemoteCommands:on_init()
    local updateNativeCommands = function(settings)
        native_commands_whitelist = S(default_native_commands)

        self.whitelist = L(settings.remote_commands.whitelist)
        for name in self.whitelist:it() do
            native_commands_whitelist:add('pcmd add '..name)
            native_commands_whitelist:add('pcmd kick '..name)
            native_commands_whitelist:add('pcmd leader '..name)
        end

        native_commands_whitelist = S(native_commands_whitelist)
    end

    self.disposeBag:add(self.addonSettings:onSettingsChanged():addAction(function(settings)
       updateNativeCommands(settings)
    end), self.addonSettings:onSettingsChanged())

    updateNativeCommands(self.addonSettings:getSettings())

    self.action_events.chat_message = windower.register_event('chat message', function(message, sender, mode, gm)
        if not gm and self.whitelist:contains(sender) then
            local args = string.split(message, ' ')
            if args[1] == 'trust' then
                windower.send_command('input // '..message)
            elseif native_commands_whitelist:contains(message) then
                self:handle_native_command(sender, message)
            end
        end
    end)
end

function TrustRemoteCommands:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function TrustRemoteCommands:handle_native_command(sender, command)
    if L{ 'pcmd add', 'pcmd kick', 'pcmd leader'}:contains(command) then 
        command = command .. " " .. sender    
    end
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



