local Event = require('cylibs/events/Luvent')
local FocusManager = require('cylibs/ui/focus/focus_manager')
local Keybind = require('cylibs/ui/input/keybind')
local Shortcut = require('settings/settings').Shortcut
local ValueRelay = require('cylibs/events/value_relay')

local Keyboard = {}
Keyboard.__index = Keyboard

Keyboard.Keys = {}
Keyboard.Keys.None = "None"
Keyboard.Flags = {}
Keyboard.Flags.Shift = 1
Keyboard.Flags.Command = 2
Keyboard.Flags.Control = 4

-- Event called when a key is pressed.
function Keyboard:on_key_pressed()
    return self.key_pressed
end

-- Event called when the chat input opens and closes.
function Keyboard:on_chat_toggle()
    return self.chat_open:onValueChanged()
end


function Keyboard.new()
    local self = setmetatable({}, Keyboard)

    self.DIKKeyMap = {
        [0x1E] = "A",     [0x30] = "B",     [0x2E] = "C",     [0x20] = "D",
        [0x12] = "E",     [0x21] = "F",     [0x22] = "G",     [0x23] = "H",
        [0x17] = "I",     [0x24] = "J",     [0x25] = "K",     [0x26] = "L",
        [0x32] = "M",     [0x31] = "N",     [0x18] = "O",     [0x19] = "P",
        [0x10] = "Q",     [0x13] = "R",     [0x1F] = "S",     [0x14] = "T",
        [0x16] = "U",     [0x2F] = "V",     [0x11] = "W",     [0x2D] = "X",
        [0x15] = "Y",     [0x2C] = "Z",
        [0x02] = "1",     [0x03] = "2",     [0x04] = "3",     [0x05] = "4",
        [0x06] = "5",     [0x07] = "6",     [0x08] = "7",     [0x09] = "8",
        [0x0A] = "9",     [0x0B] = "0",
        [0x0E] = "Backspace", [0x039] = " ",
        [0xCB] = "Left", [0xCD] = "Right", [0xC8] = "Up", [0xD0] = "Down", [0x1C] = "Enter",
        [0x01] = "Escape", [0x2A] = "LShift",
        [0x0C] = "Minus",
        [0x1D] = "LControl", [0x9D] = "RControl",
        [0x33] = ",", [0x34] = ".", [0x35] = "/", [0x28] = "\""
    }

    self.keybinds = T{}
    self.chat_open = ValueRelay.new(windower.ffxi.get_info().chat_open)
    self.key_pressed = Event.newEvent()
    self.events = {}

    self.events.keyboard = windower.register_event('keyboard', function(key, pressed, flags, blocked)
        if not pressed then
            self.chat_open:setValue(windower.ffxi.get_info().chat_open)
        end

        self:on_key_pressed():trigger(key, pressed, flags, blocked)

        if not blocked and self:isValidKeybind(key, flags) and pressed and FocusManager.shared():getFocusable() == nil then
            local keybind = Keybind.new(self:getKey(key), flags)
            self:getKeybindHandler(key, flags)(keybind, pressed)
            return true
        end

        local focusable = FocusManager.shared():getFocusable()
        if focusable and focusable.onKeyboardEvent then
            local blocked = focusable:onKeyboardEvent(key, pressed, flags, blocked)
            return blocked
        end
        return blocked
    end)

    self:setupKeybinds()

    return self
end

function Keyboard:setupKeybinds()
    local shortcuts = Shortcut:all():filter(function(shortcut)
        return shortcut.enabled == 1 and shortcut.command and shortcut.command:contains("//")
    end)
    for shortcut in shortcuts:it() do
        self:registerKeybind(shortcut.key, shortcut.flags, function(_, _)
            windower.chat.input(shortcut.command)
        end)
    end
end

function Keyboard:destroy()
    self.keybinds = T{}
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self:on_chat_toggle():removeAllActions()
    self.key_pressed:removeAllActions()
end

---
-- Returns the friendly name key for the given DIKCode (e.g. 50 -> M).
-- @treturn string The friendly name for the key.
--
function Keyboard:getKey(dikCode, flags)
    if flags == 1 then
        if self.DIKKeyMap[dikCode] == "," then
            return "<"
        elseif self.DIKKeyMap[dikCode] == "." then
            return ">"
        end
    end
    return self.DIKKeyMap[dikCode]
end

function Keyboard:getFlag(flagCode)
    if flagCode == 0 then
        return "None"
    elseif flagCode == 1 then
        return "Shift"
    elseif flagCode == 2 then
        return "Command"
    elseif flagCode == 4 then
        return "Control"
    end
    return ""..flagCode
end

function Keyboard.allKeys()
    return L{
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".","/"
    }
end

function Keyboard.allFlags()
    return L{ 0, 1, 2, 4 }
    --return L{ 0, 1, 2, 3, 4, 5 }
end

---
-- Registers a handler that will be called when the given key is pressed.
-- @tparam string key Friendly name for key.
-- @tparam Keyboard.Flags flags Keyboard flags (e.g. Control, Shift, etc.)
-- @tparam function handler Handler
--
function Keyboard:registerKeybind(keyName, flags, handler)
    if keyName and keyName ~= Keyboard.Keys.None and flags ~= nil then
        local keybind = Keybind.new(keyName, flags)
        self.keybinds[keybind:tostring()] = handler
    end
end

function Keyboard:unregisterKeybind(keyName, flags)
    if keyName and flags ~= nil then
        local keybind = Keybind.new(keyName, flags)
        self.keybinds[keybind:tostring()] = nil
    end
end

function Keyboard:hasKeybind(key, flags)
    if self:getKey(key) == nil then
        return false
    end
    local keybind = Keybind.new(self:getKey(key), flags)
    return self.keybinds[keybind:tostring()] ~= nil
end

function Keyboard:isValidKeybind(key, flags)
    local keybind = self:getKeybindHandler(key, flags)
    if not keybind then
        return false
    end
    return not windower.ffxi.get_info().chat_open
end

function Keyboard:getKeybindHandler(key, flags)
    if not self:hasKeybind(key, flags) then
        return nil
    end
    local keybind = Keybind.new(self:getKey(key), flags)
    return self.keybinds[keybind:tostring()]
end

function Keyboard:setActive(active)
    if self.active == active then
        return
    end
    self.active = active

    local keys = Keyboard.allKeys()
    for secondaryKey in L{ "", "~", "^" }:it() do
        for key in keys:it() do
            if self.active then
                windower.send_command('bind %s%s block':format(secondaryKey, key))
            else
                windower.send_command('unbind %s%s':format(secondaryKey, key))
            end
        end
    end
end

function Keyboard.input()
    if keyboardInput == nil then
        keyboardInput = Keyboard.new()
    end
    return keyboardInput
end

return Keyboard