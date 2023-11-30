local Padding = {}
Padding.__index = Padding

---
-- Creates a new Padding instance.
--
-- @tparam number top The top padding value.
-- @tparam number left The left padding value.
-- @tparam number bottom The bottom padding value.
-- @tparam number right The right padding value.
-- @treturn Padding The newly created Padding instance.
--
function Padding.new(top, left, bottom, right)
    local self = setmetatable({}, Padding)

    self.top = top
    self.left = left
    self.bottom = bottom
    self.right = right

    return self
end

---
-- Checks if this Padding instance is equal to another Padding instance.
--
-- @tparam Padding otherItem The other Padding instance to compare.
-- @treturn boolean Returns true if both instances are equal, false otherwise.
--
function Padding:__eq(otherItem)
    return self.top == otherItem.top and self.left == otherItem.left and self.bottom == otherItem.bottom
            and self.right == otherItem.right
end

---
-- Creates a new Padding instance with equal values for all sides.
--
-- @tparam number padding The padding value for all sides.
-- @treturn Padding The newly created Padding instance.
--
function Padding.equal(padding)
    return Padding.new(padding, padding, padding, padding)
end

return Padding