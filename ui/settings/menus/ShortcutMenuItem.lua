local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local Keyboard = require('cylibs/ui/input/keyboard')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local Shortcut = require('settings/settings').Shortcut

local ShortcutMenuItem = setmetatable({}, {__index = MenuItem })
ShortcutMenuItem.__index = ShortcutMenuItem

function ShortcutMenuItem.new(shortcutId, shortcutName)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Save')
    }, {}, nil, "Shortcuts", "Add a shortcut for the "..shortcutName.."."), ShortcutMenuItem)

    self.shortcutId = shortcutId
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, _, _)
        local shortcut = self:getShortcut()

        local configItems = L{
            PickerConfigItem.new('key', shortcut.key or Keyboard.allKeys()[1], Keyboard.allKeys(), function(keyName)
                return keyName
            end, "Key"),
            PickerConfigItem.new('flags', shortcut.flags or Keyboard.allFlags()[1], Keyboard.allFlags(), function(flag)
                return Keyboard.input():getFlag(flag)
            end, "Secondary Key"),
            BooleanConfigItem.new('enabled', "Enable Shortcut"),
        }

        local shortcutsEditor = ConfigEditor.fromModel(shortcut, configItems, nil, function(newSettings)
            local existingShortcut = Shortcut:get({ key = newSettings.key, flags = newSettings.flags })

            local isError = existingShortcut and existingShortcut.id ~= shortcutId
            if isError then
                return false, "This shortcut is already in use."
            else
                return true
            end
        end)

        self.disposeBag:add(shortcutsEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
            local shortcut = Shortcut({
                id = shortcutId,
                key = newSettings.key,
                flags = newSettings.flags,
                enabled = newSettings.enabled,
            })
            shortcut:save()

            Keyboard.input():unregisterKeybind(oldSettings.key, oldSettings.flags)

            if newSettings.key ~= Keyboard.Keys.None and newSettings.key and newSettings.flags and newSettings.enabled then
                local widget = windower.trust.ui.get_widget(newSettings.id)
                widget:setShortcut(newSettings.key, newSettings.flags)
            end
        end), shortcutsEditor:onConfigChanged())

        self.disposeBag:add(shortcutsEditor:onConfigValidationError():addAction(function(errorMessage)
            addon_system_error(errorMessage)
        end), shortcutsEditor:onConfigValidationError())

        return shortcutsEditor
    end

    return self
end

function ShortcutMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function ShortcutMenuItem:getShortcut()
    return Shortcut:get({ id = self.shortcutId }) or Shortcut({
        id = self.shortcutId,
        key = "A",
        flags = 1,
        enabled = false
    })
end

return ShortcutMenuItem