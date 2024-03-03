local FocusManager = require('cylibs/ui/focus/focus_manager')

local Keyboard = {}
Keyboard.__index = Keyboard

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
    }

    self.events = {}

    self.events.keyboard = windower.register_event('keyboard', function(key, pressed, flags, blocked)
        local focusable = FocusManager.shared():getFocusable()
        if focusable and focusable.onKeyboardEvent then
            local blocked = focusable:onKeyboardEvent(key, pressed, flags, blocked)
            return blocked
        end
        return blocked
    end)

    return self
end

function Keyboard:getKey(dikCode)
    return self.DIKKeyMap[dikCode]
end

function Keyboard:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
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