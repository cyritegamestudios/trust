local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local Keyboard = require('cylibs/ui/input/keyboard')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local Shortcut = require('settings/settings').Shortcut
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local ShortcutMenuItem = setmetatable({}, {__index = MenuItem })
ShortcutMenuItem.__index = ShortcutMenuItem

function ShortcutMenuItem.new(shortcutId, shortcutDescription, allowCommand)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Save')
    }, {}, nil, "Shortcuts", "Add a shortcut."), ShortcutMenuItem)

    self.shortcutId = shortcutId or string.format('shortcut_%d', os.time())
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
        if allowCommand then
            configItems:append(TextInputConfigItem.new('command', shortcut.command or '', 'Command', function(_)
                return true
            end))
        end

        local shortcutsEditor = ConfigEditor.fromModel(shortcut, configItems, nil, function(newSettings)
            if allowCommand and newSettings.command == nil or not newSettings.command:contains("//") then
                return false, "Command must start with //."
            end

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
                id = self.shortcutId,
                key = newSettings.key,
                flags = newSettings.flags,
                enabled = newSettings.enabled,
                command = newSettings.command,
                description = shortcutDescription,
            })
            shortcut:save()

            Keyboard.input():unregisterKeybind(oldSettings.key, oldSettings.flags)

            if newSettings.key ~= Keyboard.Keys.None and newSettings.key and newSettings.flags and newSettings.enabled then
                local widget = windower.trust.ui.get_widget(newSettings.id)
                if widget then
                    widget:setShortcut(newSettings.key, newSettings.flags)
                else
                    if newSettings.command and newSettings.command:length() > 0 then
                        Keyboard.input():registerKeybind(newSettings.key, newSettings.flags, function(_, _)
                            windower.chat.input(newSettings.command)
                        end)
                    end
                end
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
        enabled = false,
        command = '',
    })
end

return ShortcutMenuItem