local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local RemoteCommandsSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RemoteCommandsSettingsMenuItem.__index = RemoteCommandsSettingsMenuItem

function RemoteCommandsSettingsMenuItem.new(addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Help', 18),
    }, {}, nil, "Remote", "Allow other players to control your Trust."), RemoteCommandsSettingsMenuItem)

    self.contentViewConstructor = function(_, _)
        local configItem = MultiPickerConfigItem.new("Whitelist", L{}, L(addonSettings:getSettings().remote_commands.whitelist):sort() or L{}, function(playerName)
            return playerName
        end)

        local whitelistSettingsEditor = FFXIPickerView.withConfig(L{ configItem })
        whitelistSettingsEditor:setAllowsCursorSelection(true)

        whitelistSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = whitelistSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item and item:getText() then
                self.selectedPlayerName = item:getText()
            else
                self.selectedPlayerName = nil
            end
        end)
        if whitelistSettingsEditor:getDataSource():numberOfItemsInSection(1) > 0 then
            whitelistSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
        end
        return whitelistSettingsEditor
    end

    self.helpUrl = addonSettings:getSettings().help.wiki_base_url..'/Commands#remote-commands'
    self.disposeBag = DisposeBag.new()

    self:reloadSettings(addonSettings)

    return self
end

function RemoteCommandsSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function RemoteCommandsSettingsMenuItem:reloadSettings(addonSettings)
    self:setChildMenuItem("Add", self:getAddPlayerMenuItem(addonSettings))
    self:setChildMenuItem("Remove", MenuItem.action(function(menu)
        if self.selectedPlayerName then
            addonSettings:getSettings().remote_commands.whitelist:remove(self.selectedPlayerName)
            addonSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..self.selectedPlayerName.." can no longer tell me what to do!")
            self.selectedPlayerName = nil
            menu:showMenu(self)
        end
    end), "Remote", "Remove the selected player from the whitelist.")
    self:setChildMenuItem("Help", MenuItem.action(function(_)
        windower.open_url(self.helpUrl)
    end))
end

function RemoteCommandsSettingsMenuItem:getAddPlayerMenuItem(addonSettings)
    local addPlayerMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end)
    }, function(_, _)
        local configItems = L{
            TextInputConfigItem.new('PlayerName', 'Player Name', 'Player Name', function(_) return true  end)
        }
        local playerNameConfigEditor = ConfigEditor.new(nil, { PlayerName = '' }, configItems, nil, function(newSettings)
            return newSettings.PlayerName and newSettings.PlayerName:length() > 3
        end)

        self.disposeBag:add(playerNameConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            local playerName = newSettings.PlayerName
            local whitelist = addonSettings:getSettings().remote_commands.whitelist
            if not whitelist:contains(playerName) then
                addonSettings:getSettings().remote_commands.whitelist:add(playerName)
                addonSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..playerName.." can control me now!")
                windower.add_to_chat(122, "---== WARNING ==---- Adding a player to the whitelist will allow them to control your Trust. Please use this carefully.")
            end
        end), playerNameConfigEditor:onConfigChanged())

        self.disposeBag:add(playerNameConfigEditor:onConfigValidationError():addAction(function()
            addon_system_error("Invalid player name.")
        end), playerNameConfigEditor:onConfigValidationError())

        return playerNameConfigEditor
    end, "Remote", "Add a new player to the whitelist.")
    return addPlayerMenuItem
end

return RemoteCommandsSettingsMenuItem