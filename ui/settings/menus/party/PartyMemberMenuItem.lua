local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModeConfigEditor = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TrustModeSettings = require('TrustModeSettings')

local PartyMemberMenuItem = setmetatable({}, {__index = MenuItem })
PartyMemberMenuItem.__index = PartyMemberMenuItem

function PartyMemberMenuItem.new(partyMember)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Assist', 18),
        ButtonItem.default('Commands', 18),
    }, {}, nil, partyMember:get_name(), "See status and configure party member."), PartyMemberMenuItem)

    self.trustMode = M{['description'] = partyMember:get_name()..' Trust Mode', T{}}
    self.partyMember = partyMember
    self.partyMemberName = partyMember:get_name()

    --self.trustModeSettings = TrustModeSettings.new(partyMember:get_main_job_short(), self.partyMemberName, self.trustMode)
    --self.trustModeSettings:loadSettings()
    --self.modes = T(self.trustModeSettings:getSettings()).Default
    --self.modeNames = self.modes:keyset()

    local trustCommands = L{
        AssistCommands.new(),
        GeneralCommands.new(),
    }

    --local commands = L{}
    --for trustCommand in trustCommands:it() do
    --    commands = commands:extend(trustCommand:to_commands())
    --end
    --self.commands = commands

    self.commands = L{
        Command.new('trust start', L{}, 'Start'),
        Command.new('trust stop', L{}, 'Stop'),
        Command.new('trust follow '..windower.ffxi.get_player().name, L{}, 'Follow me'),
        Command.new('trust follow clear', L{}, 'Clear follow'),
        Command.new('trust assist '..windower.ffxi.get_player().name, L{}, 'Assist me'),
        Command.new('trust assist clear', L{}, 'Clear assist'),
        Command.new('trust assist '..windower.ffxi.get_player().name..' true', L{}, 'Mirror me in battle'),
    }

    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function PartyMemberMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function PartyMemberMenuItem:reloadSettings()
    self:setChildMenuItem("Assist", MenuItem.action(function(_)
        windower.send_command('trust assist '..self.partyMemberName)
    end, self.partyMemberName, "Assist "..self.partyMemberName.." in battle"))
    self:setChildMenuItem("Commands", self:getCommandsMenuItem())
    --self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function PartyMemberMenuItem:getCommandsMenuItem()
    --[[local commands = L{
        AssistCommands.new(main_job_trust, action_queue),
        AttackCommands.new(main_job_trust, action_queue),
        FollowCommands.new(main_job_trust, action_queue),
        GeneralCommands.new(main_job_trust, action_queue, addon_enabled, trust_mode_settings, main_trust_settings, sub_trust_settings),
        MagicBurstCommands.new(main_job_trust, main_trust_settings, action_queue),
        NukeCommands.new(main_job_trust, main_trust_settings, action_queue),
        PathCommands.new(main_job_trust, action_queue),
        PullCommands.new(main_job_trust, action_queue, main_job_trust:role_with_type("puller") or sub_job_trust:role_with_type("puller")),
        ScenarioCommands.new(main_job_trust, action_queue, party, addon_settings),
        SkillchainCommands.new(main_job_trust, weapon_skill_settings, action_queue),
    }:map(function(command)
        return command:get_command_name()
    end)]]
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
    end, self.partyMemberName, "Send commands to "..self.partyMemberName)

    commandsMenuItem:setChildMenuItem("Send", MenuItem.action(function(_)
        if not self.selectedCommand or not L{'All', 'Send'}:contains(state.IpcMode.value) then
            addon_system_error("Unable to send command.")
            return
        end
        windower.send_command('trust send '..self.partyMemberName..' '..self.selectedCommand:get_windower_command())
    end), "Send", "Send command to "..self.partyMemberName)

    commandsMenuItem:setChildMenuItem("Send All", MenuItem.action(function(_)
        if not self.selectedCommand or not L{'All', 'Send'}:contains(state.IpcMode.value) then
            addon_system_error("Unable to send command.")
            return
        end
        windower.send_command('trust sendall '..self.partyMemberName..' '..self.selectedCommand:get_windower_command())
    end), "Send All", "Send command to all party members")

    return commandsMenuItem
end

function PartyMemberMenuItem:getModesMenuItem()
    local partyMemberModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModeConfigEditor.new(L(self.modeNames), infoView, self.modes)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Set modes for "..self.partyMemberName)
    return partyMemberModesMenuItem
end

return PartyMemberMenuItem