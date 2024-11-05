local TextInputConfigItem = {}
TextInputConfigItem.__index = TextInputConfigItem
TextInputConfigItem.__type = "TextInputConfigItem"

---
-- Creates a new TextInputConfigItem instance.
--
-- @tparam string key The key in the config.
-- @tparam number minValue The minimum value in the range.
-- @tparam number maxValue The maximum value in the range.
-- @tparam number interval The range interval.
-- @tparam function Formatter for current value.
-- @treturn ConfigItem The newly created ConfigItem instance.
--
function TextInputConfigItem.new(key, placeholderText, description, validator, width)
    local self = setmetatable({}, TextInputConfigItem)

    self.key = key
    if type(placeholderText) == 'string' then
        self.placeholderText = placeholderText
    else
        self.placeholderText = placeholderText:get_windower_command()
    end
    self.description = description or key
    self.validator = validator or function(_) return true  end
    self.width = width or 175

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function TextInputConfigItem:getKey()
    return self.key
end

---
-- Gets the minimum value in the range.
--
-- @treturn number The minimum value in the range.
--
function TextInputConfigItem:getPlaceholderText()
    return self.placeholderText
end

---
-- Gets the maximum value in the range.
--
-- @treturn number The maximum value in the range.
--
function TextInputConfigItem:getValidator()
    return self.validator
end

---
-- Gets the width.
--
-- @treturn number The width.
--
function TextInputConfigItem:getWidth()
    return self.width
end

---
-- Gets the description.
--
-- @treturn string The description.
--
function TextInputConfigItem:getDescription()
    return self.description
end

---
-- Gets the formatted text.
--
-- @treturn string The formatted text.
--
function TextInputConfigItem:tostring()
    return self:getText()
end

return TextInputConfigItem