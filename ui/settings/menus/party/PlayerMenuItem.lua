local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local IpcRelay = require('cylibs/messages/ipc/ipc_relay')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')

local PlayerMenuItem = setmetatable({}, {__index = MenuItem })
PlayerMenuItem.__index = PlayerMenuItem

function PlayerMenuItem.new(partyMember, party, whitelist, trust)
    local allRoles = L{}:extend(L(player.trust.main_job:get_roles())):extend(L(player.trust.sub_job:get_roles()))

    local roles = L(allRoles:filter(function(role)
        return role.get_party_member_blacklist ~= nil
    end))

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Clear Assist', 18),
        ButtonItem.default('Commands', 18),
    }, {}, nil, partyMember:get_name(), "Send commands to party members."), PlayerMenuItem)

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
        Command.new('trust follow stop', L{}, 'Clear follow'),
        Command.new('trust assist '..windower.ffxi.get_player().name..' true', L{}, 'Assist me'),
        Command.new('trust assist clear', L{}, 'Clear assist'),
        Command.new('trust mount random', L{}, 'Call forth a mount'),
        Command.new('trust mount dismount', L{}, 'Dismount'),
    }

    self.disposeBag = DisposeBag.new()

    self:reloadSettings(roles)

    return self
end

function PlayerMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function PlayerMenuItem:reloadSettings(roles)
    self:setChildMenuItem("Clear Assist", MenuItem.action(function(_)
        self.party:set_assist_target(self.party:get_player())
        self.trust:role_with_type("follower"):set_follow_target(nil)
        addon_system_message("Assist and follow target have been cleared.")
    end, self.partyMemberName, "Clear assist and follow target."))
    self:setChildMenuItem("Commands", self:getCommandsMenuItem())
end

function PlayerMenuItem:getCommandsMenuItem()
    local commandsMenuItem = MenuItem.new(L{
        ButtonItem.default('Send All'),
    }, {}, function(_, infoView)
        local allCommands = self.commands
        local commandList = FFXIPickerView.withItems(allCommands:map(function(c) return c:get_display_name() end), L{}, false, nil, nil, nil, true)
        commandList:getDisposeBag():add(commandList:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            self.selectedCommand = allCommands[indexPath.row]
            if self.selectedCommand then
                infoView:setDescription("Send // "..self.selectedCommand:get_windower_command().." to all party members.")
            end
        end), commandList:getDelegate():didMoveCursorToItemAtIndexPath())
        commandList:setAllowsCursorSelection(true)
        return commandList
    end, "Commands", "Send commands to all party members.")

    commandsMenuItem:setChildMenuItem("Send All", MenuItem.action(function(_)
        self:sendCommand(self.selectedCommand, true)
    end), "Send All", "Send command to all party members")

    return commandsMenuItem
end

function PlayerMenuItem:sendCommand(command, sendAll)
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
        if IpcRelay.shared():is_connected(partyMemberName) then
            windower.send_command('trust send '..partyMemberName..' '..self.selectedCommand:get_windower_command())
        elseif self.whitelist:contains(partyMemberName) then
            windower.chat.input('/tell '..partyMemberName..' '..self.selectedCommand:get_windower_command())
        end
    end
end

return PlayerMenuItem