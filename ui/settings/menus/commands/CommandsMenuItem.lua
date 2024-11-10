local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local RemoteCommandsSettingsMenuItem = require('ui/settings/menus/RemoteCommandsSettingsMenuItem')
local WidgetSettingsMenuItem = require('ui/settings/menus/widgets/WidgetSettingsMenuItem')

local CommandsMenuItem = setmetatable({}, {__index = MenuItem })
CommandsMenuItem.__index = CommandsMenuItem

function CommandsMenuItem.new(commands)
    local commands = L{}:extend(commands):filter(function(command)
        return not S{ 'Default', 'Scenario', 'Sendall', 'Send' }:contains(command:get_command_name():gsub("^%l", string.upper))
    end)

    local buttonItems = commands:map(function(command)
        return ButtonItem.default(command:get_localized_command_name():gsub("^%l", string.upper), 18)
    end)

    local self = setmetatable(MenuItem.new(buttonItems, {}, nil, "Commands", "Trust addon commands."), CommandsMenuItem)

    self:reloadSettings(commands)

    return self
end

function CommandsMenuItem:destroy()
    MenuItem.destroy(self)
end

function CommandsMenuItem:reloadSettings(commands)
    for command in commands:it() do
        local commandName = command:get_localized_command_name():gsub("^%l", string.upper)

        local commandInfoMenuItem = MenuItem.new(L{
            ButtonItem.default('Confirm', 18)
        }, {}, function(_, infoView)
            if self.selectedCommand then
                local args = string.split(self.selectedCommand, " ")
                local commandArgs = command:get_args(args[4])
                local commandArgValues = {}
                for arg in commandArgs:it() do
                    commandArgValues[arg.key] = arg.getDefaultValue and arg:getDefaultValue() or ''
                end
                local commandConfigEditor = ConfigEditor.new(nil, commandArgValues, commandArgs)
                commandConfigEditor:onConfigConfirm():addAction(function(newSettings, _)
                    local commandToRun = self.selectedCommand
                    for arg in commandArgs:it() do
                        commandToRun = commandToRun..' '..newSettings[arg.key]
                    end
                    coroutine.schedule(function()
                        hud:closeAllMenus()
                        windower.send_command('input '..commandToRun)
                    end, 0.1)
                end)
                return commandConfigEditor
            end
            return nil
        end, commandName, "Configure command.")

        self:setChildMenuItem(commandName, MenuItem.new(L{
            ButtonItem.default('Configure', 18),
        }, {
            Configure = commandInfoMenuItem
        }, function(_, infoView)
            local allCommands = command:get_all_commands():sort()

            local commandList = FFXIPickerView.withItems(allCommands, allCommands[1], false, nil, nil, FFXIClassicStyle.WindowSize.Picker.Wide, true)
            commandList:setAllowsCursorSelection(true)

            commandList:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
                local item = allCommands[indexPath.row]
                if item then
                    self.selectedCommand = item

                    local args = string.split(item, " ")

                    infoView:setTitle(commandName)

                    local description = command:get_description(args[4])
                    if not description or description:empty() then
                        description = item
                    end
                    infoView:setDescription(description)
                end
            end)
            return commandList
        end, commandName, "Choose a command."))
    end
end

return CommandsMenuItem