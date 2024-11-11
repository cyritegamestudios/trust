local ConfigItem = {}
ConfigItem.__index = ConfigItem
ConfigItem.__type = "ConfigItem"

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
function ConfigItem.new(key, minValue, maxValue, interval, textFormat, description)
    local self = setmetatable({}, ConfigItem)

    self.key = key
    self.minValue = minValue
    self.maxValue = maxValue
    self.interval = interval or 1
    self.textFormat = textFormat or function(value)
        return tostring(value)
    end
    self.description = description or key

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function ConfigItem:getKey()
    return self.key
end

---
-- Gets the default value.
--
-- @treturn number The default value.
--
function ConfigItem:getDefaultValue()
    return self:getMinValue()
end

---
-- Gets the minimum value in the range.
--
-- @treturn number The minimum value in the range.
--
function ConfigItem:getMinValue()
    return self.minValue
end

---
-- Gets the maximum value in the range.
--
-- @treturn number The maximum value in the range.
--
function ConfigItem:getMaxValue()
    return self.maxValue
end

---
-- Gets the range interval.
--
-- @treturn number The range interval.
--
function ConfigItem:getInterval()
    return self.interval
end

---
-- Gets the formatted text.
--
-- @treturn function The formatted text.
--
function ConfigItem:getTextFormat()
    return self.textFormat
end

---
-- Gets the description.
--
-- @treturn string The description.
--
function ConfigItem:getDescription()
    return self.description
end

---
-- Gets the formatted text.
--
-- @treturn string The formatted text.
--
function ConfigItem:tostring()
    return self:getText()
end

return ConfigItem