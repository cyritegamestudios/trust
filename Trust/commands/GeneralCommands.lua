local TrustCommands = require('cylibs/trust/commands/trust_commands')
local GeneralTrustCommands = setmetatable({}, {__index = TrustCommands })
GeneralTrustCommands.__index = GeneralTrustCommands
GeneralTrustCommands.__class = "GeneralTrustCommands"

function GeneralTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), GeneralTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_send_command, 'Send a command to a specific player, // trust send player_name command')
    self:add_command('widget', self.handle_toggle_widget, 'Show or hide a widget, // trust widget widget_name')

    return self
end

function GeneralTrustCommands:get_command_name()
    return 'send'
end

-- // trust send player_name command
function GeneralTrustCommands:handle_send_command(...)
    local success = true
    local message

    local target_name = arg[1]

    local windower_command = ''
    for i, token in ipairs(arg) do
        if i > 1 then
            if token == 'me' then
                token = windower.ffxi.get_player().name
            end
            windower_command = windower_command..token..' '
        end
    end
    if #windower_command > 0 then
        if L{'All', 'Send'}:contains(state.IpcMode.value) then
            IpcRelay.shared():send_message(CommandMessage.new(windower_command, target_name))
            success = true
            message = 'Executing command: '..windower_command..' on '..target_name
        else
            success = false
            message = 'IpcMode must be set to All or Send to use this command'
        end
    else
        success = false
        message = 'Invalid command: '..windower_command or 'nil'
    end

    return success, message
end

function GeneralTrustCommands:handle_toggle_widget(widget_name)
    local success
    local message

    local widget_names = L{ 'trust', 'party', 'target' }
    if widget_names:contains(widget_name) then
        local is_visible = settings.hud[widget_name].visible
        is_visible = not is_visible

        settings.hud[widget_name] = visible

        config.save(settings)

        success = true
        message = "Widget "..widget_name.." is now "
        if is_visible then
            message = message.." visible"
        else
            message = message.." hidden"
        end
    else
        success = false
        message = "Valid widget names are "..widget_names:tostring()
    end

    return success, message
end

return GeneralTrustCommands