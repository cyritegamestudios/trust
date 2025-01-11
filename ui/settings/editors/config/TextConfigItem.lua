local TextConfigItem = {}
TextConfigItem.__index = TextConfigItem
TextConfigItem.__type = "TextConfigItem"

---
-- Creates a new TextConfigItem instance.
--
-- @tparam string key The key in the config.
-- @tparam function textFormat Text from values.
-- @tparam string description The description.
-- @treturn TextConfigItem The newly created text item.
--
function TextConfigItem.new(key, initialValues, textFormat, description)
    local self = setmetatable({}, TextConfigItem)

    self.key = key
    self.initialValues = initialValues
    self.textFormat = textFormat or function(values)
        return localization_util.commas(values, 'and')
    end
    self.description = description or key

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function TextConfigItem:getKey()
    return self.key
end

function TextConfigItem:getInitialValues()
    return self.initialValues
end

---
-- Gets the formatted text for a list of items.
--
-- @treturn function The formatted text.
--
function TextConfigItem:getTextFormat()
    return self.textFormat
end

---
-- Gets the text.
--
-- @treturn number The text.
--
function TextConfigItem:getText()
    return self:getTextFormat()(self.initialValues)
end

---
-- Gets the description.
--
-- @treturn number The description.
--
function TextConfigItem:getDescription()
    return self.description
end

---
-- Gets the formatted text.
--
-- @treturn string The formatted text.
--
function TextConfigItem:tostring()
    return self:getText()
end

return TextConfigItem