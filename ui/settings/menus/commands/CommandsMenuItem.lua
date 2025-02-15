local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

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

        local configureMenuItem = MenuItem.new(L{
            ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
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

        local commandMenuItem = MenuItem.new(L{
            ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        }, {
            Confirm = configureMenuItem
        }, nil, commandName, "Choose a command.")

        commandMenuItem.contentViewConstructor = function(_, infoView)
            local allCommands = command:get_all_commands():sort()

            self.selectedCommand = allCommands[1]

            local update_for_command = function(selectedCommand)
                self.selectedCommand = selectedCommand

                local args = string.split(selectedCommand, " ")

                local commandArgs = command:get_args(args[4])
                if commandArgs:length() > 0 then
                    commandMenuItem:setChildMenuItem("Confirm", configureMenuItem)
                else
                    commandMenuItem:setChildMenuItem("Confirm", MenuItem.action(function(_)
                        coroutine.schedule(function()
                            hud:closeAllMenus()
                            windower.send_command('input '..self.selectedCommand)
                        end, 0.1)
                    end), commandName, "Choose a command.")
                end

                infoView:setTitle(commandName)

                local description = command:get_description(args[4], true)
                if not description or description:empty() then
                    description = selectedCommand
                end
                infoView:setDescription(description)
            end

            local configItem = MultiPickerConfigItem.new("Commands", L{ allCommands[1] }, allCommands, function(command)
                return tostring(command)
            end)

            local commandList = FFXIPickerView.withConfig(configItem, false, FFXIClassicStyle.WindowSize.Picker.Wide)
            commandList:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
                local item = allCommands[indexPath.row]
                if item then
                    update_for_command(item)
                end
            end)

            update_for_command(self.selectedCommand)

            return commandList
        end

        self:setChildMenuItem(commandName, commandMenuItem)
    end
end

return CommandsMenuItem