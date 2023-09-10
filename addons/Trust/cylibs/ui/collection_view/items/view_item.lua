local ViewItem = {}
ViewItem.__index = ViewItem
ViewItem.__type = "ViewItem"

---
-- Creates a new ViewItem.
-- @tparam View view The view associated with this item.
-- @treturn ViewItem The newly created ViewItem.
--
function ViewItem.new(view)
    local self = setmetatable({}, ViewItem)
    self.view = view
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
-- Checks if this ViewItem is equal to another.
-- @tparam ViewItem otherItem The other ViewItem to compare with.
-- @treturn boolean True if the ViewItems are equal, false otherwise.
--
function ViewItem:__eq(otherItem)
    return self.view == otherItem.view
end

return ViewItem
