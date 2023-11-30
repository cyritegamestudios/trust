local PickerItem = {}
PickerItem.__index = PickerItem
PickerItem.__type = "PickerItem"

---
-- Creates a new PickerItem.
--
-- @tparam any item The item associated with the PickerItem.
-- @tparam boolean selected The selection status of the item.
-- @treturn PickerItem The created PickerItem.
--
function PickerItem.new(item, selected)
    local self = setmetatable({}, PickerItem)

    self.item = item
    self.selected = selected

    return self
end

---
-- Gets the item associated with the PickerItem.
--
-- @treturn any The associated item.
--
function PickerItem:getItem()
    return self.item
end

---
-- Checks if the PickerItem is selected.
--
-- @treturn boolean `true` if the PickerItem is selected, `false` otherwise.
--
function PickerItem:isSelected()
    return self.selected
end

---
-- Checks if another PickerItem is equal to this one.
--
-- @tparam PickerItem otherItem The PickerItem to compare with.
-- @treturn boolean `true` if the PickerItems are equal, `false` otherwise.
--
function PickerItem:__eq(otherItem)
    return otherItem.__type == PickerItem.__type
            and self:getItem() == otherItem:getItem()
            and self:isSelected() == otherItem:isSelected()
end

return PickerItem