local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local TargetCommands = setmetatable({}, {__index = TrustCommands })
TargetCommands.__index = TargetCommands
TargetCommands.__class = "TargetCommands"

function TargetCommands.new(trustSettings, trustSettingsMode)
    local self = setmetatable(TrustCommands.new(), TargetCommands)

    self.trust_settings = trustSettings
    self.trust_settings_mode = trustSettingsMode

    self:add_command('auto', function(_) return self:handle_toggle_mode('AutoTargetMode', 'Auto', 'Off')  end, 'Automatically target aggroed monsters after defeating one', L{
        PickerConfigItem.new('mode_value', state.AutoTargetMode.value, L{ "Auto", "Off" }, nil, "Mirror Combat Position")
    })
    self:add_command('mirror', function(_) return self:handle_toggle_mode('AutoTargetMode', 'Mirror', 'Off')  end, 'Automatically target what the assist target is targeting', L{
        PickerConfigItem.new('mode_value', state.AutoTargetMode.value, L{ "Mirror", "Off" }, nil, "Mirror Combat Position")
    })
    self:add_command('retry', self.handle_retry_autotarget, 'Attempt to retry auto target', L{
        PickerConfigItem.new('should_retry', "true", L{ "true", "false" }, nil, "Retry Auto Target")
    })

    return self
end

function TargetCommands:get_command_name()
    return 'target'
end

function TargetCommands:handle_toggle_mode(mode_var_name, on_value, off_value, force_on)
    local success = true
    local message

    local mode_var = get_state(mode_var_name)
    if not force_on and mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end

    return success, message
end

function TargetCommands:handle_retry_autotarget(_, should_retry)
    local success = true
    local message

    should_retry = should_retry:lower()

    if S{ "true", "false" }:contains(should_retry) then
        should_retry = should_retry == "true"

        local current_settings = self.trust_settings:getSettings()[self.trust_settings_mode.value].TargetSettings
        current_settings.Retry = should_retry

        self.trust_settings:saveSettings(true)

        success = true
        if should_retry then
            message = "Auto target will now retry"
        else
            message = "Auto target will not retry"
        end
    else
        success = false
        message = "Invalid argument "..(should_retry or "nil")
    end

    return success, message
end

return TargetCommands