local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local HealCommands = setmetatable({}, {__index = TrustCommands })
HealCommands.__index = HealCommands
HealCommands.__class = "HealCommands"

function HealCommands.new()
    local self = setmetatable(TrustCommands.new(), HealCommands)

    -- AutoHealMode
    self:add_command('default', self.handle_set_heal_mode, 'Heal self and party', L{
        PickerConfigItem.new('mode_value', state.AutoHealMode.value, L(state.AutoHealMode:options()), nil, "Healing")
    })

    return self
end

function HealCommands:get_command_name()
    return 'heal'
end

function HealCommands:get_localized_command_name()
    return 'Heal'
end

-- // trust heal heal_mode
function HealCommands:handle_set_heal_mode(mode_value)
    local success = true
    local message

    handle_set('AutoHealMode', mode_value)

    return success, message
end

function HealCommands:get_all_commands()
    local result = TrustCommands.get_all_commands(self)

    result:append('// trust heal auto')
    result:append('// trust heal emergency')
    result:append('// trust heal off')

    return result
end


local StatusRemovalCommands = setmetatable({}, {__index = TrustCommands })
StatusRemovalCommands.__index = StatusRemovalCommands
StatusRemovalCommands.__class = "StatusRemovalCommands"

function StatusRemovalCommands.new()
    local self = setmetatable(TrustCommands.new(), StatusRemovalCommands)

    -- AutoStatusRemovalMode
    self:add_command('default', self.handle_set_status_mode, 'Remove status effects from self and party', L{
        PickerConfigItem.new('mode_value', state.AutoStatusRemovalMode.value, L(state.AutoStatusRemovalMode:options()), nil, "Status Removals")
    })

    return self
end

function StatusRemovalCommands:get_command_name()
    return 'statusremoval'
end

function StatusRemovalCommands:get_localized_command_name()
    return 'Status Removal'
end

-- // trust status status_removal_mode
function StatusRemovalCommands:handle_set_status_mode(mode_value)
    local success = true
    local message

    handle_set('AutoStatusRemovalMode', mode_value)

    return success, message
end

function StatusRemovalCommands:get_all_commands()
    local result = TrustCommands.get_all_commands(self)

    result:append('// trust statusremoval auto')
    result:append('// trust statusremoval off')

    return result
end

return function()
    return HealCommands, StatusRemovalCommands
end
