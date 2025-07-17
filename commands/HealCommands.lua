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

    self:add_command('blacklistall', self.handle_blacklist_all, 'Toggle healing for groups of party or alliance members', L{
        PickerConfigItem.new('group_name', 'Alter Egos', L{ 'Alter Egos' }, nil, "Group Name"),
    })

    local update_commands = function(party_members)
        local party_member_names = party_members:map(function(p) return p:get_name() end)

        self:add_command('blacklist', self.handle_blacklist_party_member, 'Toggle healing for a party or alliance member', L{
            PickerConfigItem.new('command', 'add', L{ 'add', 'remove', 'clear' }, function(command) return localization_util.firstUpper(command) end, "Command"),
            PickerConfigItem.new('party_member_name', party_member_names[1], party_member_names, nil, "Party Member Name"),
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

function HealCommands:handle_blacklist_all(_, ...)
    local success
    local message

    local group_name = table.concat({...}, " ") or ""

    local group_to_alliance_members = T{
        ['Alter Egos'] = function()
            return self.trust:get_party():get_party_members(false):filter(function(p)
                return p:is_trust()
            end)
        end,
    }

    local group = group_to_alliance_members[group_name] and group_to_alliance_members[group_name]()
    if group then
        success = true

        if group:length() > 0 then
            message = string.format("%s have been added to the healing blacklist", localization_util.commas(group:map(function(a) return a:get_name() end)))
            for alliance_member in group:it() do
                self:handle_blacklist_party_member(_, 'Add', alliance_member:get_name())
            end
        else
            message = string.format("No alliance members matching %s found", group_name)
        end
    else
        success = false
        message = string.format("Invalid group name %s, valid options are %s", group_name or 'nil', localization_util.commas(L(group_to_alliance_members:keyset())))
    end

    return success, message
end

function HealCommands:handle_blacklist_party_member(_, command, party_member_name)
    local success
    local message

    command = command and localization_util.firstUpper(command)

    local valid_commands = L{ 'Add', 'Remove', 'Clear' }
    if valid_commands:contains(command) then
        local healer = self.trust:role_with_type("healer")

        if command == 'Clear' then
            success = true
            message = "All party members have been removed from the healing blacklist"

            healer:set_party_member_blacklist(L{})
        else
            local party_member = player.alliance:get_alliance_member_named(localization_util.firstUpper(party_member_name), true)
            if party_member then
                success = true

                local blacklist = healer:get_party_member_blacklist():filter(function(name)
                    return name ~= party_member_name
                end)
                if command == 'Add' then
                    blacklist:append(party_member:get_name())
                    message = string.format("%s has been added to the healing blacklist", party_member:get_name())
                elseif command == 'Remove' then
                    message = string.format("%s has been removed from the healing blacklist", party_member:get_name())
                end
                healer:set_party_member_blacklist(blacklist)
            else
                success = false
                message = string.format("Invalid party member %s or party member out of range", party_member_name or "")
            end
        end
    else
        success = false
        message = string.format("Invalid command %s, valid commands are %s", command or 'nil', localization_util.commas(valid_commands))
    end

    return success, message
end

function HealCommands:get_all_commands()
    local result = TrustCommands.get_all_commands(self)

    for blacklist_command in L{ 'Add', 'Remove', 'Clear' }:it() do
        result:append(string.format('// trust heal blacklist %s', blacklist_command:lower()))
    end

    for blacklist_group in L{ 'Alter Egos' }:it() do
        result:append(string.format('// trust heal blacklistall %s', blacklist_group))
    end

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
    return 'Ailments'
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
