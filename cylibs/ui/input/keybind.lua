local Keybind = {}
Keybind.__index = Keybind
Keybind.__type = "Keybind"

function Keybind.new(key, flags, enable_in_chat)
    local self = setmetatable({}, Keybind)
    if key == nil then
        print(debug.traceback())
    end
    self.key = key
    self.flags = flags or 0
    self.enable_in_chat = enable_in_chat
    return self
end

function Keybind:getKey()
    return self.key
end

function Keybind:getFlags()
    return self.flags
end

function Keybind:enableInChat()
    return self.enable_in_chat
end

function Keybind:tostring()
    return self.key..'_'..self.flags
end

function Keybind:__eq(otherItem)
    return self:getKey() == otherItem:getKey()
        and self:getFlags() == otherItem:getFlags()
end

return Keybind