local TrustCommands = require('cylibs/trust/commands/trust_commands')
local MenuTrustCommands = setmetatable({}, {__index = TrustCommands })
MenuTrustCommands.__index = MenuTrustCommands
MenuTrustCommands.__class = "MenuTrustCommands"

function MenuTrustCommands.new(trust, action_queue, hud)
    local self = setmetatable(TrustCommands.new(), MenuTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.hud = hud

    self:add_command('default', self.handle_toggle_menu, 'Show and hide the Trust menu')

    return self
end

function MenuTrustCommands:get_command_name()
    return 'menu'
end

-- // trust menu
function MenuTrustCommands:handle_toggle_menu(_)
    local success = true
    local message

    coroutine.schedule(function()
        self.hud:toggleMenu()
    end, 0.2)

    return success, message
end

return MenuTrustCommands