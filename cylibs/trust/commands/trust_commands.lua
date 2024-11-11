local TrustCommands = {}
TrustCommands.__index = TrustCommands
TrustCommands.__class = "TrustCommands"

function TrustCommands.new()
    local self = setmetatable({
        commands = T{};
    }, TrustCommands)

    return self
end

function TrustCommands:add_command(command_name, handler, description, args)
    self.commands[command_name] = {
        callback = function(...)
            return handler(self, T{ ... }:unpack())
        end,
        description = description or '',
        args = args or L{},
    }
end

function TrustCommands:get_command_name()
    return nil
end

function TrustCommands:get_localized_command_name()
    return self:get_command_name()
end

function TrustCommands:is_valid_command(command_name, ...)
    return S(self.commands:keyset()):contains(command_name) or self.commands['default']
end

function TrustCommands:handle_command(...)
    local cmd = select(1, ...)
    local full_cmd = table.concat({...}, " ") or ""

    local trust_command = self.commands[cmd] or self.commands[full_cmd] or self.commands['default']
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

function TrustCommands:get_description(command_name, include_args)
    command_name = command_name or 'default'
    for name, command in pairs(self.commands) do
        if name == command_name then
            local description = command.description
            if include_args then
                local args = self:get_args(command_name)
                if args:length() > 0 then
                    description = description..', Command: // trust '..self:get_command_name()
                    if command_name ~= 'default' then
                        description = description..' '..command_name
                    end
                    for arg in args:it() do
                        description = description..' '..arg.key
                    end
                end
            end
            return description
        end
    end
    return ""
end

function TrustCommands:get_args(command_name)
    command_name = command_name or 'default'
    for name, command in pairs(self.commands) do
        if name == command_name then
            return command.args or L{}
        end
    end
    return L{}
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

function TrustCommands:to_commands()
    local result = L{}
    for command_name, command in pairs(self.commands) do
        if command_name == 'default' then
            result:append(Command.new('// trust '..self:get_command_name(), L{}, command.description))
        else
            result:append(Command.new('// trust '..self:get_command_name()..' '..command_name, L{}, command.description))
        end
    end
    return result
end

return TrustCommands



