local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Shortcut = require('settings/settings').Shortcut
local ShortcutMenuItem = require('ui/settings/menus/ShortcutMenuItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local ShortcutListMenuItem = setmetatable({}, {__index = MenuItem })
ShortcutListMenuItem.__index = ShortcutListMenuItem

function ShortcutListMenuItem.new()
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Remove', 18),
    }, {}, nil, "Shortcuts", "Add or edit keyboard shortcuts."), ShortcutListMenuItem)

    self.contentViewConstructor = function(_, infoView, _)
        local shortcuts = L(Shortcut:all() or L{})

        local configItem = MultiPickerConfigItem.new("Shortcuts", L{}, shortcuts, function(shortcut)
            return shortcut.command or shortcut.description
        end, "Shortcuts")

        local shortcutEditor = FFXIPickerView.withConfig(L{ configItem })
        shortcutEditor:setAllowsCursorSelection(true)

        shortcutEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local shortcut = self:getShortcuts()[indexPath.row]
            if shortcut then
                self:setChildMenuItem("Edit", ShortcutMenuItem.new(shortcut.id, shortcut.command or shortcut.id, true))
                infoView:setDescription(shortcut.command or shortcut.description)
            else
                infoView:setDescription("Add or edit keyboard shortcuts.")
            end
        end)
        return shortcutEditor
    end

    self.disposeBag = DisposeBag.new()

    self:reloadSettings(addonSettings)

    return self
end

function ShortcutListMenuItem:destroy()
    MenuItem.destroy(self)
end

function ShortcutListMenuItem:getShortcuts()
    return L(Shortcut:all() or L{})
end

function ShortcutListMenuItem:reloadSettings(addonSettings)
    self:setChildMenuItem("Add", ShortcutMenuItem.new(nil, 'shortcut', true))
    --[[self:setChildMenuItem("Remove", MenuItem.action(function(menu)
        if self.selectedPlayerName then
            Whitelist:delete({ id = self.selectedPlayerName })
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..self.selectedPlayerName.." can no longer tell me what to do!")
            self.selectedPlayerName = nil
            menu:showMenu(self)
        end
    end), "Remote", "Remove the selected player from the whitelist.")]]
end

function ShortcutListMenuItem:getAddShortcutMenuItem()
    local addShortcutMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {}, function(_, _, _)

    end, "Shortcuts", "Create a new shortcut.")
end

--[[function ShortcutListMenuItem:getAddPlayerMenuItem(addonSettings)
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
end]]

return ShortcutListMenuItem