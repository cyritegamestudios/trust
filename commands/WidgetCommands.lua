local TrustCommands = require('cylibs/trust/commands/trust_commands')
local WidgetCommands = setmetatable({}, {__index = TrustCommands })
WidgetCommands.__index = WidgetCommands
WidgetCommands.__class = "WidgetCommands"

function WidgetCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), WidgetCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_toggle_widget, 'Show or hide a widget, // trust widget widget_name')
    self:add_command('toggle', self.handle_toggle_widget, 'Show or hide a widget, // trust widget toggle widget_name')

    return self
end

function WidgetCommands:get_command_name()
    return 'widget'
end

function WidgetCommands:handle_toggle_widget(widget_name)
    local success
    local message

    local widget_names = L{ 'trust', 'party', 'target' }
    if widget_names:contains(widget_name) then
        settings_root = settings.hud[widget_name]
        if widget_name == 'trust' then
            settings_root = settings.hud
        end

        local is_visible = settings_root.visible
        is_visible = not is_visible

        settings_root.visible = is_visible

        config.save(settings)

        local widget = hud:getWidget(widget_name)
        if widget and widget_name ~= 'target' then
            widget:setVisible(is_visible)
            widget:layoutIfNeeded()
        end

        success = true
        message = "Widget "..widget_name.." is now "
        if is_visible then
            message = message.."visible"
        else
            message = message.."hidden"
        end
    else
        success = false
        message = "Valid widget names are "..widget_names:tostring()
    end

    return success, message
end

return WidgetCommands