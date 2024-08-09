local TrustCommands = {}
TrustCommands.__index = TrustCommands
TrustCommands.__class = "TrustCommands"

function TrustCommands.new()
    local self = setmetatable({
        commands = T{};
    }, TrustCommands)

    return self
end

function TrustCommands:add_command(command_name, handler, description)
    self.commands[command_name] = {
        callback = function(...)
            return handler(self, T{ ... }:unpack())
        end,
        description = description or ''
    }
end

function TrustCommands:get_command_name()
    return nil
end

function TrustCommands:is_valid_command(command_name, ...)
    return S(self.commands:keyset()):contains(command_name) or self.commands['default']
end

function TrustCommands:handle_command(...)
    local cmd = select(1, ...)

    local trust_command = self.commands[cmd] or self.commands['default']
    if trust_command then
        local success, message = trust_command.callback(...)
        if success then
            if message then
                addon_message(207, self.__class..' '..message)
            end
        else
            error(self.__class, message)
        end
        return true
    end
    return false
end

function TrustCommands:description()
    local result = '========================\n'
    for command_name, command in pairs(self.commands) do
        result = result..'// trust '..self:get_command_name()..' '..command_name..': '..command.description..'\n'
    end
    return result
end

function TrustCommands:get_description(command_name)
    for name, command in pairs(self.commands) do
        if name == command_name then
            return command.description
        end
    end
    return ""
end

function TrustCommands:get_all_commands()
    local result = L{}
    for command_name, command in pairs(self.commands) do
        if command_name == 'default' then
            result:append('// trust '..self:get_command_name())
        else
            result:append('// trust '..self:get_command_name()..' '..command_name)
        end
    end
    return result
end

return TrustCommands



