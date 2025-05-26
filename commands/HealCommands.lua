local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local HealCommands = setmetatable({}, {__index = TrustCommands })
HealCommands.__index = HealCommands
HealCommands.__class = "HealCommands"

function HealCommands.new(trust)
    local self = setmetatable(TrustCommands.new(), HealCommands)

    self.trust = trust

    self:add_command('default', function(_) return self:handle_toggle_mode('AutoHealMode', 'Auto', 'Off')  end, 'Heal self and party')
    self:add_command('auto', function(_) return self:handle_set_mode('AutoHealMode', 'Auto')  end, 'Heal self and party')
    self:add_command('emergency', function(_) return self:handle_set_mode('AutoHealMode', 'Emergency')  end, 'Heal self and party using Emergency threshold')
    self:add_command('off', function(_) return self:handle_set_mode('AutoHealMode', 'Off')  end, 'Do not heal self and party')

    local update_commands = function(party_members)
        local party_member_names = party_members:map(function(p) return p:get_name() end)

        self:add_command('ignore', self.handle_ignore_party_member, 'Toggle healing for a party or alliance member', L{
            PickerConfigItem.new('party_member_name', party_member_names[1], party_member_names, nil, "Party Member Name"),
            BooleanConfigItem.new('ignore', "Ignore Party Member"),
        })
    end

    trust:get_party():on_party_members_changed():addAction(function(party_members)
        update_commands(party_members)
    end)

    update_commands(trust:get_party():get_party_members(true))

    return self
end

function HealCommands:get_command_name()
    return 'heal'
end

function HealCommands:get_localized_command_name()
    return 'Heal'
end

function HealCommands:handle_ignore_party_member(_, party_member_name, ignore)
    local success
    local message

    local party_member = player.alliance:get_alliance_member_named(localization_util.firstUpper(party_member_name))
    if party_member then
        success = true

        if ignore == nil then ignore = true end

        local healer = self.trust:role_with_type("healer")

        local blacklist = healer:get_party_member_blacklist():filter(function(name)
            return name ~= party_member_name
        end)
        if ignore == "true" then
            blacklist:append(party_member:get_name())
            message = string.format("%s has been added to the healing blacklist", party_member:get_name())
        else
            message = string.format("%s has been removed from the healing blacklist", party_member:get_name())
        end
        healer:set_party_member_blacklist(blacklist)
    else
        success = false
        message = string.format("Invalid party member %s", party_member_name or "")
    end

    return success, message
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
