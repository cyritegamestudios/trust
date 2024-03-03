local TrustCommands = require('cylibs/trust/commands/trust_commands')
local WidgetCommands = setmetatable({}, {__index = TrustCommands })
WidgetCommands.__index = WidgetCommands
WidgetCommands.__class = "WidgetCommands"

function WidgetCommands.new(trust, action_queue, addon_settings, widgetManager)
    local self = setmetatable(TrustCommands.new(), WidgetCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.addon_settings = addon_settings
    self.widgetManager = widgetManager

    --self:add_command('default', self.handle_toggle_widget, 'Show or hide a widget, // trust widget widget_name')
    --self:add_command('toggle', self.handle_toggle_widget, 'Show or hide a widget, // trust widget toggle widget_name')
    self:add_command('save', self.handle_save_settings, 'Saves current widget settings')

    return self
end

function WidgetCommands:get_command_name()
    return 'widget'
end

function WidgetCommands:handle_save_settings()
    local success = true
    local message = "Widget settings saved to addons/Trust/data/settings.xml"

    self.widgetManager:saveChanges()

    return success, message
end

function WidgetCommands:handle_toggle_widget(widget_name)
    local success
    local message

    local widget_names = L{ 'trust', 'party', 'target' }

    local is_visible
    if widget_name == 'trust' then
        is_visible = not self.addon_settings:getSettings().trust_widget.visible
        self.addon_settings:getSettings().trust_widget.visible = is_visible
    elseif widget_name == 'party' then
        is_visible = not self.addon_settings:getSettings().party_widget.visible
        self.addon_settings:getSettings().party_widget.visible = is_visible
    elseif widget_name == 'target' then
        is_visible = not self.addon_settings:getSettings().target_widget.visible
        self.addon_settings:getSettings().target_widget.visible = is_visible
    else
        success = false
        message = "Valid widget names are "..widget_names:tostring()

        return success, message
    end
    self.addon_settings:saveSettings()

    success = true
    message = "Widget "..widget_name.." is now "
    if is_visible then
        message = message.."visible"
    else
        message = message.."hidden"
    end

    return success, message
end

return WidgetCommands