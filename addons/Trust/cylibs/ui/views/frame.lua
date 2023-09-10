local Frame = {}
Frame.__index = Frame

---
-- Creates a new Frame object with specified coordinates and dimensions.
--
-- @tparam number x The x-coordinate of the frame.
-- @tparam number y The y-coordinate of the frame.
-- @tparam number width The width of the frame.
-- @tparam number height The height of the frame.
-- @treturn Frame The newly created Frame object.
--
function Frame.new(x, y, width, height)
    local self = setmetatable({}, Frame)

    self.x = x
    self.y = y
    self.width = width
    self.height = height

    return self
end

function Frame:__eq(otherItem)
    return self.x == otherItem.x and self.y == otherItem.y and self.width == otherItem.width
            and self.height == otherItem.height
end

return Frame