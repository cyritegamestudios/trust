---
-- A layout class for positioning item views.
--
-- @classmod Layout
--

local Layout = {}
Layout.__index = Layout

---
-- Creates a new Layout instance.
--
-- @tparam number itemOffset The offset between items in the layout.
-- @treturn Layout The newly created Layout instance.
--
function Layout.new(itemOffset)
    local self = setmetatable({}, Layout)

    self.itemOffset = itemOffset
    self.xOffset = 0
    self.yOffset = 0
    self.width = 0
    self.height = 0

    return self
end

---
-- Destroys the layout, cleaning up its resources.
--
function Layout:destroy()
end

---
-- Positions the provided item view based on the layout strategy.
--
-- This function should be overridden by subclasses to define custom layout behavior.
--
-- @tparam [ListItemView] itemViews The item views to be positioned.
-- @tparam [ListItem] items The ordered items.
--
function Layout:layout(itemViews, items)
    -- This function should be overridden by subclasses.
end

---
-- Sets the offset for the layout.
--
-- @tparam number xOffset The x-coordinate offset for the layout.
-- @tparam number yOffset The y-coordinate offset for the layout.
--
function Layout:setOffset(xOffset, yOffset)
    self.xOffset = xOffset
    self.yOffset = yOffset
end

---
-- Gets the current offset of the layout.
--
-- @treturn number xOffset The x-coordinate offset of the layout.
-- @treturn number yOffset The y-coordinate offset of the layout.
--
function Layout:getOffset()
    return self.xOffset, self.yOffset
end

---
-- Sets the size of the layout.
--
-- @tparam number width The width of the layout.
-- @tparam number height The height of the layout.
--
function Layout:setSize(width, height)
    self.width = width
    self.height = height
end

---
-- Gets the current size of the layout
--
-- @treturn number width The width of the layout.
-- @treturn number height The height of the layout.
--
function Layout:getSize()
    return self.width, self.height
end

return Layout
