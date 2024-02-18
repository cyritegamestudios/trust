local Alignment = {}
Alignment.__index = Alignment
Alignment.__type = "Alignment"

Alignment.Type = {}
Alignment.Type.Left = "Left"
Alignment.Type.Center = "Center"
Alignment.Type.Right = "Right"
Alignment.Type.Top = "Top"
Alignment.Type.Bottom = "Bottom"

---
-- Creates a new alignment instance.
--
-- @tparam string type Alignment type
-- @treturn Alignment The newly created Alignment instance.
--
function Alignment.new(type)
    local self = setmetatable({}, Alignment)
    self.type = type
    return self
end

function Alignment.left()
    return Alignment.new(Alignment.Type.Left)
end

function Alignment.right()
    return Alignment.new(Alignment.Type.Right)
end

function Alignment.center()
    return Alignment.new(Alignment.Type.Center)
end

function Alignment.top()
    return Alignment.new(Alignment.Type.Top)
end

function Alignment.bottom()
    return Alignment.new(Alignment.Type.Bottom)
end

---
-- Gets the alignment type.
--
-- @treturn string The alignment type.
--
function Alignment:getType()
    return self.type
end

function Alignment:__eq(otherItem)
    return otherItem.__type == Alignment.__type
            and self.type == otherItem:getType()
end

return Alignment