local Nukes = require('cylibs/res/nukes')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local BlackMageTrustCommands = setmetatable({}, {__index = TrustCommands })
BlackMageTrustCommands.__index = BlackMageTrustCommands
BlackMageTrustCommands.__class = "BlackMageTrustCommands"

function BlackMageTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), BlackMageTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_show_blacklist, 'See enabled elements')
    self:add_command('toggle', self.handle_toggle_element, 'Toggle an element for nuking and magic bursting, // trust nuke toggle element_name')
    self:add_command('reset', self.handle_reset_blacklist, 'Re-enable all elements')

    return self
end

function BlackMageTrustCommands:get_command_name()
    return 'blm'
end

function BlackMageTrustCommands:is_valid_command(command_name, ...)
    if self:get_nuker() then
        return TrustCommands.is_valid_command(self, command_name, ...)
    end
    return false
end

function BlackMageTrustCommands:get_nuker()
    return self.trust:role_with_type("nuker")
end

function BlackMageTrustCommands:get_valid_elements()
    return S{ 'earth', 'lightning', 'water', 'fire', 'ice', 'wind', 'light', 'dark' }
end

-- // trust blm nuke
function BlackMageTrustCommands:handle_show_blacklist()
    local success
    local message

    local elements = Nukes.get_disabled_elements()

    success = true
    message = "Disabled elements are: "..elements:tostring()

    return success, message
end

-- // trust blm nuke toggle [earth|lightning|water|fire|ice|wind|light|dark]
function BlackMageTrustCommands:handle_toggle_element(_, element_name)
    local success
    local message

    if self:get_valid_elements():contains(element_name) then
        local is_enabled = Nukes.toggle(element_name)
        if is_enabled then
            success = true
            message = "Nukes of type "..element_name.." are enabled"
        else
            success = true
            message = "Nukes of type "..element_name.." are disabled"
        end
    else
        success = false
        message = "Invalid element "..(element_name or 'nil')..", valid elements are "..self:get_valid_elements():tostring()
    end

    return success, message
end

-- // trust blm nuke reset
function BlackMageTrustCommands:handle_reset_blacklist()
    local success
    local message

    Nukes.reset()

    success = true
    message = "Nukes of all types are enabled"

    return success, message
end

return BlackMageTrustCommands