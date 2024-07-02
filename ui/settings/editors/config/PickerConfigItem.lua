local PickerConfigItem = {}
PickerConfigItem.__index = PickerConfigItem
PickerConfigItem.__type = "PickerConfigItem"

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
function PickerConfigItem.new(key, initialValue, allValues, textFormat)
    local self = setmetatable({}, PickerConfigItem)

    self.key = key
    self.initialValue = initialValue
    self.allValues = allValues
    self.textFormat = textFormat or function(value)
        return tostring(value)
    end

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function PickerConfigItem:getKey()
    return self.key
end

---
-- Gets the minimum value in the range.
--
-- @treturn number The minimum value in the range.
--
function PickerConfigItem:getInitialValue()
    return self.initialValue
end

---
-- Gets the maximum value in the range.
--
-- @treturn number The maximum value in the range.
--
function PickerConfigItem:getAllValues()
    return self.allValues
end

---
-- Gets the formatted text.
--
-- @treturn function The formatted text.
--
function PickerConfigItem:getTextFormat()
    return self.textFormat
end

---
-- Gets the formatted text.
--
-- @treturn string The formatted text.
--
function PickerConfigItem:tostring()
    return self:getText()
end

return PickerConfigItem