local PickerItemMapper = {}
PickerItemMapper.__index = PickerItemMapper
PickerItemMapper.__type = "PickerItemMapper"

---
-- Creates a new PickerItemMapper. Maps a PickerItem to a result type.
--
-- @treturn PickerItemMapper The newly created PickerItemMapper.
--
function PickerItemMapper.new()
    local self = setmetatable({}, PickerItemMapper)
    return self
end

---
-- Returns whether this PickerItemMapper can map a given picker item.
--
-- @tparam PickerItem pickerItem The PickerItem.
-- @treturn boolean True if this mapper can map a picker item.
--
function PickerItemMapper:canMap(pickerItem)
    return false
end

---
-- Gets the mapped picker item.
--
-- @tparam PickerItem pickerItem The PickerItem.
-- @treturn table The mapped picker item.
--
function PickerItemMapper:map(pickerItem)
    return pickerItem
end

return PickerItemMapper