local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')
local Whitelist = require('settings/settings').Whitelist

local RemoteCommandsSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RemoteCommandsSettingsMenuItem.__index = RemoteCommandsSettingsMenuItem

function RemoteCommandsSettingsMenuItem.new()
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Help', 18),
    }, {}, nil, "Remote", "Allow other players to control your Trust."), RemoteCommandsSettingsMenuItem)

    self.contentViewConstructor = function(_, _)
        local configItem = MultiPickerConfigItem.new("Whitelist", L{}, self:getWhitelist():sort() or L{}, function(playerName)
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

    self.helpUrl = 'https://github.com/cyritegamestudios/trust/wiki/Commands#remote-commands'
    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function RemoteCommandsSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function RemoteCommandsSettingsMenuItem:getWhitelist()
    return Whitelist:all():map(function(user) return user.id end)
end

function RemoteCommandsSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddPlayerMenuItem())
    self:setChildMenuItem("Remove", MenuItem.action(function(menu)
        if self.selectedPlayerName then
            Whitelist:delete({ id = self.selectedPlayerName })
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..self.selectedPlayerName.." can no longer tell me what to do!")
            self.selectedPlayerName = nil
            menu:showMenu(self)
        end
    end), "Remote", "Remove the selected player from the whitelist.")
    self:setChildMenuItem("Help", MenuItem.action(function(_)
        windower.open_url(self.helpUrl)
    end))
end

function RemoteCommandsSettingsMenuItem:getAddPlayerMenuItem()
    local addPlayerMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end)
    }, function(_, _, showMenu)
        local configItems = L{
            TextInputConfigItem.new('PlayerName', 'Player Name', 'Player Name', function(_) return true  end)
        }

        local playerNameConfigEditor = ConfigEditor.new(nil, { PlayerName = '' }, configItems, nil, function(newSettings)
            if newSettings.PlayerName == nil or newSettings.PlayerName:length() <= 3 then
                return false, "Invalid player name."
            end
            if self:getWhitelist():contains(newSettings.playerName) then
                return false, string.format("%s is already on the whitelist.", newSettings.playerName)
            end
            return true
        end, showMenu)

        self.disposeBag:add(playerNameConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            local playerName = newSettings.PlayerName
            local user = Whitelist({
                id = playerName,
            })
            user:save()
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..playerName.." can control me now!")
            windower.add_to_chat(122, "---== WARNING ==---- Adding a player to the whitelist will allow them to control your Trust. Please use this carefully.")
        end), playerNameConfigEditor:onConfigChanged())

        self.disposeBag:add(playerNameConfigEditor:onConfigValidationError():addAction(function(errorMessage)
            addon_system_error(errorMessage)
        end), playerNameConfigEditor:onConfigValidationError())

        return playerNameConfigEditor
    end, "Remote", "Add a new player to the whitelist.")
    return addPlayerMenuItem
end

return RemoteCommandsSettingsMenuItem