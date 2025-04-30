local ViewItem = {}
ViewItem.__index = ViewItem
ViewItem.__type = "ViewItem"
ViewItem.__class = "ViewItem"

---
-- Creates a new ViewItem.
-- @tparam View view The view associated with this item.
-- @tparam boolean keepView Whether the view should be destroyed when the cell is destroyed.
-- @treturn ViewItem The newly created ViewItem.
--
function ViewItem.new(view, keepView, viewSize, offset)
    local self = setmetatable({}, ViewItem)
    self.view = view
    self.keepView = keepView
    self.viewSize = viewSize
    self.offset = offset
    return self
end

---
-- Gets the view associated with this item.
-- @treturn View The associated view.
--
function ViewItem:getView()
    return self.view
end

---
-- Gets whether the underlying view should be destroyed.
-- @treturn boolean Whether the view should be destroyed.
--
function ViewItem:shouldDestroyView()
    return not self.keepView
end

---
-- Gets the view offset.
-- @treturn {number, number} View offset.
--
function ViewItem:getOffset()
    return self.offset or { x = 0, y = 0 }
end

---
-- Checks if this ViewItem is equal to another.
-- @tparam ViewItem otherItem The other ViewItem to compare with.
-- @treturn boolean True if the ViewItems are equal, false otherwise.
--
function ViewItem:__eq(otherItem)
    return self.view == otherItem.view and self.viewSize == otherItem.viewSize
end

return ViewItem
