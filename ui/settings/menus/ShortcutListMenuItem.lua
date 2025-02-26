local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Keyboard = require('cylibs/ui/input/keyboard')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Shortcut = require('settings/settings').Shortcut
local ShortcutMenuItem = require('ui/settings/menus/ShortcutMenuItem')

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
            self.selectedShortcutId = shortcut and shortcut.id
        end)

        return shortcutEditor
    end

    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function ShortcutListMenuItem:destroy()
    MenuItem.destroy(self)
end

function ShortcutListMenuItem:getShortcuts()
    return L(Shortcut:all() or L{})
end

function ShortcutListMenuItem:reloadSettings()
    self:setChildMenuItem("Add", ShortcutMenuItem.new(nil, 'shortcut', true))
    self:setChildMenuItem("Remove", MenuItem.action(function(menu)
        if self.selectedShortcutId then
            local shortcut = Shortcut:get({ id = self.selectedShortcutId })
            if shortcut then
                Keyboard.input():unregisterKeybind(shortcut.key, shortcut.flags)
                addon_system_message(string.format("Shortcut for %s removed.", shortcut.command or shortcut.description or ''))
                Shortcut:delete({ id = self.selectedShortcutId })
                self.selectedShortcutId = nil
                menu:showMenu(self)
            end

        end
    end), "Shortcut", "Remove the selected keyboard shortcut.")
end

return ShortcutListMenuItem