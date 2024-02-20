local TrustCommands = require('cylibs/trust/commands/trust_commands')
local WidgetCommands = setmetatable({}, {__index = TrustCommands })
WidgetCommands.__index = WidgetCommands
WidgetCommands.__class = "WidgetCommands"

function WidgetCommands.new(trust, action_queue, addon_settings)
    local self = setmetatable(TrustCommands.new(), WidgetCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.addon_settings = addon_settings

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

    self.addon_settings:reloadSettings()

    local is_visible
    if widget_name == 'trust' then
        is_visible = not self.addon_settings:getSettings().hud.trust.visible
        self.addon_settings:getSettings().hud.trust.visible = is_visible
    elseif widget_name == 'party' then
        is_visible = not self.addon_settings:getSettings().hud.party.visible
        self.addon_settings:getSettings().hud.party.visible = is_visible
    elseif widget_name == 'target' then
        is_visible = not self.addon_settings:getSettings().hud.target.visible
        self.addon_settings:getSettings().hud.target.visible = is_visible
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