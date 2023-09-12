local TextStyle = require('cylibs/ui/style/text_style')

local TextItem = {}
TextItem.__index = TextItem
TextItem.__type = "TextItem"

---
-- Creates a new TextItem instance.
--
-- @tparam string text The text content of the item.
-- @tparam TextStyle style The style to apply to the text.
-- @tparam string pattern (optional) The pattern used for formatting the text.
-- @treturn TextItem The newly created TextItem instance.
--
function TextItem.new(text, style, pattern)
    local self = setmetatable({}, TextItem)

    self.text = text
    self.style = style
    self.pattern = pattern or '${text}'

    return self
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function TextItem:getText()
    return self.text
end

---
-- Sets the text for this TextItem.
--
-- @tparam string text The new text to set.
--
function TextItem:setText(text)
    self.text = text
end

---
-- Gets the settings for rendering the text item.
--
-- @treturn table The settings for rendering.
--
function TextItem:getSettings()
    local settings = {}

    settings.pos = {}
    settings.padding = self.style:getPadding()
    settings.text = {}
    settings.text.alpha = 255
    settings.text.red = self.style:getFontColor().red
    settings.text.green = self.style:getFontColor().green
    settings.text.blue = self.style:getFontColor().blue
    settings.text.font = self.style:getFontName()
    settings.text.size = self.style:getFontSize()
    settings.text.stroke = {}
    settings.text.stroke.width = self.style:getStrokeWidth()
    settings.text.stroke.alpha = self.style:getStrokeAlpha()
    settings.flags = {}
    settings.flags.bold = self.style:isBold()
    settings.flags.right = false
    settings.flags.draggable = false

    return settings
end

---
-- Gets the style associated with the text item.
--
-- @treturn TextStyle The style of the text item.
--
function TextItem:getStyle()
    return self.style
end

---
-- Gets the pattern used for formatting the text.
--
-- @treturn string The pattern.
--
function TextItem:getPattern()
    return self.pattern
end

---
-- Gets the identifier of the item (same as the text content).
--
-- @treturn string The identifier.
--
function TextItem:getIdentifier()
    return self.text
end

---
-- Checks if this TextItem is equal to another TextItem.
--
-- @tparam TextItem otherItem The other TextItem to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function TextItem:__eq(otherItem)
    return otherItem.__type == TextItem.__type
            and self.text == otherItem:getText()
end

return TextItem