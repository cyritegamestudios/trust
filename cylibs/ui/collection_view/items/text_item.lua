local Alignment = require('cylibs/ui/layout/alignment')

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
    self.horizontalAlignment = Alignment.left()
    self.offset = { x = 0, y = 0 }

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
-- Returns the horizontal alignment for this TextItem.
--
-- @treturn Alignment The alignment.
--
function TextItem:getHorizontalAlignment()
    return self.horizontalAlignment
end

---
-- Sets the horizontal alignment for this TextItem.
--
-- @tparam Alignment alignment The new alignment to set.
--
function TextItem:setHorizontalAlignment(horizontalAlignment)
    self.horizontalAlignment = horizontalAlignment
end

---
-- Returns the auto resize policy for this TextItem.
--
-- @treturn boolean The autoresize policy.
--
function TextItem:shouldAutoResize()
    return self.autoResize
end

---
-- Sets the auto resize policy for this TextItem.
--
-- @tparam boolean autoResize The new auto resize policy to set.
--
function TextItem:setShouldAutoResize(autoResize)
    self.autoResize = autoResize
end

---
-- Returns the word wrap policy for this TextItem.
--
-- @treturn boolean The word wrap policy.
--
function TextItem:shouldWordWrap()
    return self.wordWrap
end

---
-- Sets the word wrap policy for this TextItem.
--
-- @tparam boolean wordWrap The new word wrap policy to set.
--
function TextItem:setShouldWordWrap(wordWrap)
    self.wordWrap = wordWrap
end

---
-- Gets the text truncation policy for this TextItem.
--
-- @treturn boolean The text truncation policy.
--
function TextItem:shouldTruncateText()
    return self.truncate_text
end

---
-- Sets the text truncation policy for this TextItem.
--
-- @tparam boolean truncate_text The new text truncation policy to set.
--
function TextItem:setShouldTruncateText(truncate_text)
    self.truncate_text = truncate_text
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
    settings.text.stroke.alpha = self.style:getStrokeColor().alpha
    settings.text.stroke.red = self.style:getStrokeColor().red
    settings.text.stroke.green = self.style:getStrokeColor().green
    settings.text.stroke.blue = self.style:getStrokeColor().blue
    settings.flags = {}
    settings.flags.bold = self.style:isBold()
    settings.flags.italic = self.style:isItalic()
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
-- Sets the text offset from center.
--
-- @tparam number x X-offset
-- @tparam number y Y-offset
--
function TextItem:setOffset(x, y)
    self.offset = { x = x, y = y}
end

---
-- Returns the text offset from center.
--
-- @treturn table The {x, y} offset
--
function TextItem:getOffset()
    return self.offset
end

---
-- Sets the text size override.
--
-- @tparam number width Width
-- @tparam number height Height
--
function TextItem:setSize(width, height)
    self.size = { width = width, height = height}
end

---
-- Returns the text size override.
--
-- @treturn table The {width, height} size
--
function TextItem:getSize()
    return self.size
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

function TextItem:tostring()
    return self:getText()
end

return TextItem