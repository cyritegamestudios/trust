local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local IpcRelay = require('cylibs/messages/ipc/ipc_relay')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')

local PartyMemberMenuItem = setmetatable({}, {__index = MenuItem })
PartyMemberMenuItem.__index = PartyMemberMenuItem

function PartyMemberMenuItem.new(partyMember, party, whitelist, trust)
    local allRoles = L{}:extend(L(player.trust.main_job:get_roles())):extend(L(player.trust.sub_job:get_roles()))

    local roles = L(allRoles:filter(function(role)
        return role.get_party_member_blacklist ~= nil
    end))

    local configButtonItem = ButtonItem.default('Config', 18)
    configButtonItem:setEnabled(roles:length() > 0)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Assist', 18),
        ButtonItem.default('Commands', 18),
        configButtonItem
    }, {}, nil, partyMember:get_name(), "See status and configure party member."), PartyMemberMenuItem)

    self.trustMode = M{['description'] = partyMember:get_name()..' Trust Mode', T{}}
    self.partyMember = partyMember
    self.partyMemberName = partyMember:get_name()
    self.party = party
    self.whitelist = whitelist or S{}
    self.trust = trust

    self.commands = L{
        Command.new('trust start', L{}, 'Start'),
        Command.new('trust stop', L{}, 'Stop'),
        Command.new('trust follow '..windower.ffxi.get_player().name, L{}, 'Follow me'),
        Command.new('trust follow clear', L{}, 'Clear follow'),
        Command.new('trust assist '..windower.ffxi.get_player().name, L{}, 'Assist me'),
        Command.new('trust assist clear', L{}, 'Clear assist'),
        Command.new('trust assist '..windower.ffxi.get_player().name..' true', L{}, 'Mirror me in battle'),
        Command.new('trust mount random', L{}, 'Call forth a mount'),
    }

    self.disposeBag = DisposeBag.new()

    self:reloadSettings(roles)

    return self
end

function PartyMemberMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function PartyMemberMenuItem:reloadSettings(roles)
    self:setChildMenuItem("Assist", MenuItem.action(function(_)
        windower.send_command('trust assist '..self.partyMemberName)
    end, self.partyMemberName, "Assist "..self.partyMemberName.." in battle."))
    self:setChildMenuItem("Commands", self:getCommandsMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem(roles))
end

function PartyMemberMenuItem:getCommandsMenuItem()
    local commandsMenuItem = MenuItem.new(L{
        ButtonItem.default('Send'),
        ButtonItem.default('Send All'),
    }, {}, function(_, infoView)
        local allCommands = self.commands
        local commandList = FFXIPickerView.withItems(allCommands:map(function(c) return c:get_display_name() end), L{}, false, nil, nil, nil, true)
        commandList:getDisposeBag():add(commandList:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            self.selectedCommand = allCommands[indexPath.row]
            if self.selectedCommand then
                infoView:setDescription("Send // "..self.selectedCommand:get_windower_command().." to "..self.partyMemberName)
            end
        end), commandList:getDelegate():didMoveCursorToItemAtIndexPath())
        commandList:setAllowsCursorSelection(true)
        return commandList
    end, self.partyMemberName, "Send commands to "..self.partyMemberName..".")

    commandsMenuItem:setChildMenuItem("Send", MenuItem.action(function(_)
        self:sendCommand(self.selectedCommand, false)
    end), "Send", "Send command to "..self.partyMemberName)

    commandsMenuItem:setChildMenuItem("Send All", MenuItem.action(function(_)
        self:sendCommand(self.selectedCommand, true)
    end), "Send All", "Send command to all party members")

    return commandsMenuItem
end

function PartyMemberMenuItem:sendCommand(command, sendAll)
    if not command or not L{'All', 'Send'}:contains(state.IpcMode.value) then
        addon_system_error("Unable to send command.")
        return
    end

    local partyMemberNames = L{ self.partyMemberName }
    if sendAll then
        partyMemberNames = self.party:get_party_members(false)
                :filter(function(p) return not p:is_trust() end)
                :map(function(p) return p:get_name() end)
    end

    for partyMemberName in partyMemberNames:it() do
        if IpcRelay.shared():is_connected(self.partyMemberName) then
            windower.send_command('trust send '..partyMemberName..' '..self.selectedCommand:get_windower_command())
        elseif self.whitelist:contains(partyMemberName) then
            windower.chat.input('/tell '..partyMemberName..' '..self.selectedCommand:get_windower_command())
        end
    end
end

function PartyMemberMenuItem:getConfigMenuItem(roles)
    local configMenuItem = MenuItem.new(L{}, {}, nil, "Config", "Choose which roles to perform on this player.", false, function()
        return roles:length() > 0
    end)

    for role in roles:it() do
        configMenuItem:setChildMenuItem(role:get_type():gsub("^%l", string.upper), MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_, _)
            local partyMemberNames = self.party:get_party_members(false):map(function(party_member)
                return party_member:get_name()
            end)
            local partyMemberPickerView = FFXIPickerView.withItems(partyMemberNames, role:get_party_member_blacklist() or L{}, true)
            self.disposeBag:add(partyMemberPickerView:on_pick_items():addAction(function(_, selectedItems)
                local newPartyMemberNames = selectedItems:map(function(item)
                    return item:getText()
                end)
                role:set_party_member_blacklist(newPartyMemberNames)
                if newPartyMemberNames:length() > 0 then
                    self.party:add_to_chat(self.party:get_player(), "Alright, I'll ignore "..localization_util.commas(newPartyMemberNames, "and").." for the "..role:get_type().." role until the addon reloads!")
                else
                    self.party:add_to_chat(self.party:get_player(), "Alright, I'll perform the "..role:get_type().." role for everyone in my party!")
                end
            end), partyMemberPickerView:on_pick_items())

            return partyMemberPickerView
        end, role:get_type():gsub("^%l", string.upper), "Choose party members to ignore for this role."))
    end

    return configMenuItem
end

return PartyMemberMenuItem