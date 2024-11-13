local MountAction = require('cylibs/actions/mount')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SoundCommands = setmetatable({}, {__index = TrustCommands })
SoundCommands.__index = SoundCommands
SoundCommands.__class = "SoundCommands"

function SoundCommands.new(mediaPlayer)
    local self = setmetatable(TrustCommands.new(), SoundCommands)

    self.mediaPlayer = mediaPlayer

    self:add_command('default', self.handle_toggle_sound, 'Toggles sound effects from Trust')

    self:add_command('enable', function(_)
        return self:handle_set_sound_enabled(true)
    end, 'Enables sound effects from Trust')

    self:add_command('disable', function(_)
        return self:handle_set_sound_enabled(false)
    end, 'Disables sound effects from Trust')

    return self
end

function SoundCommands:get_command_name()
    return 'sounds'
end

-- // trust sound
function SoundCommands:handle_toggle_sound()
    if self.mediaPlayer:isEnabled() then
        return self:handle_set_sound_enabled(false)
    else
        return self:handle_set_sound_enabled(true)
    end
end

-- // trust sound [enable | disable]
function SoundCommands:handle_set_sound_enabled(is_enabled)
    local success = true
    local message

    if is_enabled then
        message = "Sound effects from Trust are now enabled"
    else
        message = "Sound effects from Trust are now disabled"
    end
    self.mediaPlayer:setEnabled(is_enabled)

    return success, message
end

return SoundCommands