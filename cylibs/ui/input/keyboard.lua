local FocusManager = require('cylibs/ui/focus/focus_manager')
local Keybind = require('cylibs/ui/input/keybind')

local Keyboard = {}
Keyboard.__index = Keyboard

Keyboard.Keys = {}
Keyboard.Flags = {}
Keyboard.Flags.Shift = 1
Keyboard.Flags.Command = 2
Keyboard.Flags.Control = 4


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
        [0xCB] = "Left", [0xCD] = "Right",
        [0x01] = "Escape", [0x2A] = "LShift",
        [0x0C] = "Minus",
        [0x1D] = "LControl", [0x9D] = "RControl",
    }

    self.keybinds = T{}
    self.events = {}

    self.events.keyboard = windower.register_event('keyboard', function(key, pressed, flags, blocked)
        if not blocked and self:hasKeybind(key, flags) and FocusManager.shared():getFocusable() == nil then
            local keybind = Keybind.new(self:getKey(key), flags)
            self:getKeybindHandler(key, flags)(keybind, pressed)
            blocked = true
            return blocked
        end

        --[[local dictKey = key..'_'..flags
        local view = self.keybinds[dictKey]
        if view then
            local focusable = FocusManager.shared():getFocusable()
            if focusable then
                focusable:resignFocus()
            end
            if view:requestFocus() then
                view:setNeedsLayout()
                view:layoutIfNeeded()
                return true
            end
            return true
        end]]

        local focusable = FocusManager.shared():getFocusable()
        if focusable and focusable.onKeyboardEvent then
            local blocked = focusable:onKeyboardEvent(key, pressed, flags, blocked)
            return blocked
        end
        return blocked
    end)

    return self
end

function Keyboard:destroy()
    self.keybinds = T{}
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
end

---
-- Returns the friendly name key for the given DIKCode (e.g. 50 -> M).
-- @treturn string The friendly name for the key.
--
function Keyboard:getKey(dikCode)
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
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
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
    local keybind = Keybind.new(keyName, flags)
    self.keybinds[keybind:tostring()] = handler
end

function Keyboard:unregisterKeybind(keyName, flags)
    local keybind = Keybind.new(keyName, flags)
    self.keybinds[keybind:tostring()] = nil
end

function Keyboard:hasKeybind(key, flags)
    if self:getKey(key) == nil then
        return false
    end
    local keybind = Keybind.new(self:getKey(key), flags)
    return self.keybinds[keybind:tostring()] ~= nil
end

function Keyboard:getKeybindHandler(key, flags)
    if not self:hasKeybind(key, flags) then
        return nil
    end
    local keybind = Keybind.new(self:getKey(key), flags)
    return self.keybinds[keybind:tostring()]
end



function Keyboard.input()
    if keyboardInput == nil then
        keyboardInput = Keyboard.new()
    end
    return keyboardInput
end



return Keyboard