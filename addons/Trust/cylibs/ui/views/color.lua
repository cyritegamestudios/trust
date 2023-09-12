local Color = {}
Color.__index = Color
Color.__type = "Color"

---
-- Creates a new Color instance.
--
-- @tparam[opt=255] number alpha The alpha value (transparency) of the color (0-255).
-- @tparam[opt=0] number red The red component of the color (0-255).
-- @tparam[opt=0] number green The green component of the color (0-255).
-- @tparam[opt=0] number blue The blue component of the color (0-255).
-- @treturn Color The newly created Color instance.
--
function Color.new(alpha, red, green, blue)
    local self = setmetatable({}, Color)

    self.alpha = alpha or 255
    self.red = red or 0
    self.green = green or 0
    self.blue = blue or 0

    return self
end

---
-- Returns a new Color object with the specified alpha value.
--
-- @tparam number alpha The alpha value (0 to 1).
-- @treturn Color The new Color object with the adjusted alpha value.
--
function Color:withAlpha(alpha)
    return Color.new(alpha, self.red, self.green, self.blue)
end

---
-- Checks if two Color objects are equal.
--
-- @tparam Color otherItem The other Color object to compare.
-- @treturn boolean Returns `true` if the colors are equal, `false` otherwise.
--
function Color:__eq(otherItem)
    return self.alpha == otherItem.alpha and self.red == otherItem.red
            and self.green == otherItem.green and self.blue == otherItem.blue
end

---- Constants

-- @treturn Color Black color.
Color.black = Color.new(255, 0, 0, 0)

-- @treturn Color White color.
Color.white = Color.new(255, 255, 255, 255)

-- @treturn Color Light grey color.
Color.lightGrey = Color.new(255, 205, 205, 205)

-- @treturn Color Clear color.
Color.clear = Color.new(0, 0, 0, 0)

-- @treturn Color Green color.
Color.green = Color.new(255, 0, 255, 0)

-- @treturn Color Red color.
Color.red = Color.new(255, 255, 132, 132)

-- @treturn Color Blue color.
Color.blue = Color.new(255, 132, 132, 255)

return Color
