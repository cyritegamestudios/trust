local element_util = require('cylibs/util/element_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MagicBurstTrustCommands = setmetatable({}, {__index = TrustCommands })
MagicBurstTrustCommands.__index = MagicBurstTrustCommands
MagicBurstTrustCommands.__class = "MagicBurstTrustCommands"

function MagicBurstTrustCommands.new(trust, trust_settings, action_queue)
    local self = setmetatable(TrustCommands.new(), MagicBurstTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.action_queue = action_queue

    -- AutoMagicBurstMode
    self:add_command('default', function(_) return self:handle_toggle_mode('AutoMagicBurstMode', 'Auto', 'Off')  end, 'Toggle magic burst on and off')
    self:add_command('auto', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Auto')  end, 'Magic burst with spells of any element')
    self:add_command('off', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Off')  end, 'Disable magic bursting')
    self:add_command('earth', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Earth')  end, 'Magic burst with earth spells')
    self:add_command('lightning', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Lightning')  end, 'Magic burst with lightning spells')
    self:add_command('water', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Water')  end, 'Magic burst with water spells')
    self:add_command('fire', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Fire')  end, 'Magic burst with fire spells')
    self:add_command('ice', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Ice')  end, 'Magic burst with ice spells')
    self:add_command('wind', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Wind')  end, 'Magic burst with wind spells')
    self:add_command('light', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Light')  end, 'Magic burst with light spells')
    self:add_command('dark', function(_) return self:handle_set_mode('AutoMagicBurstMode', 'Dark')  end, 'Magic burst with dark spells')

    -- Blacklist
    local elements = L{ 'fire', 'ice', 'wind', 'earth', 'lightning', 'water', 'light', 'dark' }
    self:add_command('toggle', self.handle_toggle_element, 'Toggle an element for magic bursting', L{
        PickerConfigItem.new('element_name', elements[1], elements, function(v) return v:gsub("^%l", string.upper) end, "Element"),
    })
    self:add_command('enable', self.handle_enable_element, 'Remove an element from the blacklist for magic bursting', L{
        PickerConfigItem.new('element_name', elements[1], elements, function(v) return v:gsub("^%l", string.upper) end, "Element"),
    })
    self:add_command('disable', self.handle_disable_element, 'Blacklist an element for magic bursting', L{
        PickerConfigItem.new('element_name', elements[1], elements, function(v) return v:gsub("^%l", string.upper) end, "Element"),
    })
    self:add_command('reset', self.handle_reset_blacklist, 'Re-enable all elements')

    return self
end

function MagicBurstTrustCommands:get_command_name()
    return 'mb'
end

function MagicBurstTrustCommands:get_localized_command_name()
    return 'Magic Burst'
end

function MagicBurstTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

function MagicBurstTrustCommands:get_valid_elements()
    return S{ 'earth', 'lightning', 'water', 'fire', 'ice', 'wind', 'light', 'dark' }
end

-- // trust mb [auto, earth, lightning, water, fire, ice, wind, light, dark]
function MagicBurstTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
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

function MagicBurstTrustCommands:handle_set_mode(mode_name, mode_value)
    local success = true
    local message

    handle_set(mode_name, mode_value)

    return success, message
end

-- // trust mb toggle [earth|lightning|water|fire|ice|wind|light|dark]
function MagicBurstTrustCommands:handle_toggle_element(_, element_name)
    local success
    local message

    if self:get_valid_elements():contains(element_name) then
        element_name = element_name:gsub("^%l", string.upper)

        local current_settings = self.trust_settings:getSettings()[state.MainTrustSettingsMode.value].NukeSettings

        local blacklist = S(current_settings.Blacklist)
        local is_enabled = blacklist:contains(element_util[element_name])
        if is_enabled then
            blacklist:remove(element_util[element_name])

            success = true
            message = "Magic bursts of type "..element_name.." are enabled"
        else
            blacklist:add(element_util[element_name])

            success = true
            message = "Magic bursts of type "..element_name.." are disabled"
        end

        current_settings.Blacklist = L(blacklist)

        self.trust_settings:saveSettings(true)
    else
        success = false
        message = "Invalid element "..(element_name or 'nil')..", valid elements are "..self:get_valid_elements():tostring()
    end

    return success, message
end

-- // trust mb enable [earth|lightning|water|fire|ice|wind|light|dark]
function MagicBurstTrustCommands:handle_enable_element(_, element_name)
    return self:handle_set_element(element_name, true)
end

-- // trust mb disable [earth|lightning|water|fire|ice|wind|light|dark]
function MagicBurstTrustCommands:handle_disable_element(_, element_name)
    return self:handle_set_element(element_name, false)
end

function MagicBurstTrustCommands:handle_set_element(element_name, enabled)
    local success
    local message

    if self:get_valid_elements():contains(element_name) then
        element_name = element_name:gsub("^%l", string.upper)

        local current_settings = self.trust_settings:getSettings()[state.MainTrustSettingsMode.value].NukeSettings

        local blacklist = L(current_settings.Blacklist)
        if enabled then
            blacklist = blacklist:filter(function(e) return e:get_name() ~= element_name end)

            success = true
            message = "Magic bursts of type "..element_name.." are enabled"
        else
            if not blacklist:contains(element_util[element_name]) then
                blacklist:append(element_util[element_name])
            end

            success = true
            message = "Magic bursts of type "..element_name.." are disabled"
        end

        current_settings.Blacklist = L(blacklist)

        self.trust_settings:saveSettings(true)
    else
        success = false
        message = "Invalid element "..(element_name or 'nil')..", valid elements are "..self:get_valid_elements():tostring()
    end

    return success, message
end

-- // trust mb reset
function MagicBurstTrustCommands:handle_reset_blacklist()
    local success
    local message

    local current_settings = self.trust_settings:getSettings()[state.MainTrustSettingsMode.value].NukeSettings
    current_settings.Blacklist:clear()

    self.trust_settings:saveSettings(true)

    success = true
    message = "Magic bursts of all types are enabled"

    return success, message
end

return MagicBurstTrustCommands
