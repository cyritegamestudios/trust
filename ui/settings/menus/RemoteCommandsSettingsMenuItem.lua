local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local WidgetSettingsMenuItem = require('ui/settings/menus/widgets/WidgetSettingsMenuItem')

local RemoteCommandsSettingsMenuItem = setmetatable({}, {__index = MenuItem })
RemoteCommandsSettingsMenuItem.__index = RemoteCommandsSettingsMenuItem

function RemoteCommandsSettingsMenuItem.new(addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Help', 18),
    }, {}, nil, "Remote", "Allow other players to control your Trust."), RemoteCommandsSettingsMenuItem)

    self.contentViewConstructor = function(_, _)
        local whitelistView = FFXIPickerView.withItems(L(addonSettings:getSettings().remote_commands.whitelist):sort() or L{}, L{})
        whitelistView:setAllowsCursorSelection(true)
        whitelistView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = whitelistView:getDataSource():itemAtIndexPath(indexPath)
            if item and item:getText() then
                self.selectedPlayerName = item:getText()
            else
                self.selectedPlayerName = nil
            end
        end)
        if whitelistView:getDataSource():numberOfItemsInSection(1) > 0 then
            whitelistView:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
        end
        return whitelistView
    end

    self.helpUrl = addonSettings:getSettings().help.wiki_base_url..'/Commands#remote-commands'

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
        local playerNameView = FFXITextInputView.new('', "Player name")
        playerNameView:setTitle("WARNING: this player will be able to control your Trust")
        playerNameView:setShouldRequestFocus(true)
        playerNameView:onTextChanged():addAction(function(_, playerName)
            if playerName:length() > 3 then
                local whitelist = addonSettings:getSettings().remote_commands.whitelist
                if not whitelist:contains(playerName) then
                    addonSettings:getSettings().remote_commands.whitelist:add(playerName)
                    addonSettings:saveSettings(true)
                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..playerName.." can control me now!")
                    windower.add_to_chat(122, "---== WARNING ==---- Adding a player to the whitelist will allow them to control your Trust. Please use this carefully.")
                end
            end
        end)
        return playerNameView
    end, "Remote", "Add a new player to the whitelist.")
    return addPlayerMenuItem
end

return RemoteCommandsSettingsMenuItem