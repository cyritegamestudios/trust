local PickerItem = {}
PickerItem.__index = PickerItem
PickerItem.__type = "PickerItem"

---
-- Creates a new ConfigItem instance.
--
-- @tparam string key The key in the config.
-- @tparam number minValue The minimum value in the range.
-- @tparam number maxValue The maximum value in the range.
-- @tparam number interval The range interval.
-- @tparam function Formatter for current value.
-- @treturn ConfigItem The newly created ConfigItem instance.
--
function PickerItem.new(currentValue, allValues, textFormat)
    local self = setmetatable({}, PickerItem)

    self.currentValue = currentValue
    self.allValues = allValues
    self.textFormat = textFormat or function(value)
        return tostring(value)
    end

    return self
end

---
-- Gets the current value.
--
-- @treturn number The current value.
--
function PickerItem:getCurrentValue()
    return self.currentValue
end

---
-- Sets the current value.
--
-- @tparam number newValue The new value
--
function PickerItem:setCurrentValue(newValue)
    self.currentValue = newValue
end

---
-- Gets all possible values.
--
-- @treturn list All possible values.
--
function PickerItem:getAllValues()
    return self.allValues
end

---
-- Gets the formatted text.
--
-- @treturn function The formatted text.
--
function PickerItem:getTextFormat()
    return self.textFormat
end

return PickerItem