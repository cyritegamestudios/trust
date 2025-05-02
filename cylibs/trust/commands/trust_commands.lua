local TrustCommands = {}
TrustCommands.__index = TrustCommands
TrustCommands.__class = "TrustCommands"

function TrustCommands.new()
    local self = setmetatable({
        commands = T{};
    }, TrustCommands)

    return self
end

function TrustCommands:add_command(command_name, handler, description, args, include_args_in_command_list)
    self.commands[command_name] = {
        callback = function(...)
            return handler(self, T{ ... }:unpack())
        end,
        description = description or '',
        args = args or L{},
        include_args_in_command_list = include_args_in_command_list
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
            addon_system_error(message..".")
        end
        return true
    end
    return false
end

function TrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

function TrustCommands:handle_set_mode(mode_name, mode_value, suppress_help_text)
    local success = true
    local message

    if suppress_help_text then
        get_state(mode_name):set(mode_value)
    else
        handle_set(mode_name, mode_value)
    end

    return success, message
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
            if command.include_args_in_command_list and command.args and command.args:length() == 1
                    and command.args[1].getAllValues then
                for value in command.args[1]:getAllValues():it() do
                    result:append('// trust '..self:get_command_name()..' '..command_name..' '..value)
                end
            end
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



