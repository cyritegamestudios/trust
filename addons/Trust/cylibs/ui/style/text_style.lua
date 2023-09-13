local Color = require('cylibs/ui/views/color')

---
-- @module TextStyle
--

local TextStyle = {}
TextStyle.__index = TextStyle
TextStyle.__type = "TextStyle"

---
-- Creates a new TextStyle instance.
--
-- @tparam Color selectedBackgroundColor The selected background color.
-- @tparam Color defaultBackgroundColor The default background color.
-- @tparam string fontName The font name.
-- @tparam number fontSize The font size.
-- @tparam Color fontColor The font color.
-- @tparam Color highlightColor The highlighted font color.
-- @tparam number padding The padding on each side.
-- @tparam number strokeWidth The stroke width.
-- @tparam number strokeAlpha The stroke alpha.
-- @tparam boolean bold Whether the text should be bolded.
-- @treturn TextStyle The newly created TextStyle instance.
--
function TextStyle.new(selectedBackgroundColor, defaultBackgroundColor, fontName, fontSize, fontColor, highlightColor, padding, strokeWidth, strokeAlpha, bold)
    local self = setmetatable({}, TextStyle)

    self.selectedBackgroundColor = selectedBackgroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.fontName = fontName
    self.fontSize = fontSize
    self.fontColor = fontColor
    self.highlightColor = highlightColor
    self.padding = padding
    self.strokeWidth = strokeWidth
    self.strokeAlpha = strokeAlpha
    self.bold = bold

    return self
end

---
-- Gets the selected background color.
--
-- @treturn Color The selected background color.
--
function TextStyle:getSelectedBackgroundColor()
    return self.selectedBackgroundColor
end

---
-- Gets the default background color.
--
-- @treturn Color The default background color.
--
function TextStyle:getDefaultBackgroundColor()
    return self.defaultBackgroundColor
end

---
-- Gets the font name.
--
-- @treturn string The font name.
--
function TextStyle:getFontName()
    return self.fontName
end

---
-- Gets the font size.
--
-- @treturn number The font size.
--
function TextStyle:getFontSize()
    return self.fontSize
end

---
-- Gets the font color.
--
-- @treturn Color The font color.
--
function TextStyle:getFontColor()
    return self.fontColor
end

---
-- Gets the highlighted font color.
--
-- @treturn Color The font color.
--
function TextStyle:getHighlightColor()
    return self.highlightColor
end

---
-- Gets the padding.
--
-- @treturn number The padding.
--
function TextStyle:getPadding()
    return self.padding
end

---
-- Gets the stroke width.
--
-- @treturn number The stroke width.
--
function TextStyle:getStrokeWidth()
    return self.strokeWidth
end

---
-- Gets the stroke alpha.
--
-- @treturn number The stroke alpha.
--
function TextStyle:getStrokeAlpha()
    return self.strokeAlpha
end

---
-- Gets the value of bold.
--
-- @treturn boolean Value of bold.
--
function TextStyle:isBold()
    return self.bold
end

TextStyle.Default = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            12,
            Color.white,
            Color.lightGrey,
            2,
            0,
            0,
            false
    ),
    TextSmall = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            10,
            Color.white,
            Color.lightGrey,
            2,
            0,
            0,
            false
    ),
    Button = TextStyle.new(
            Color.lightGrey:withAlpha(50),
            Color.clear,
            "Arial",
            12,
            Color.white,
            Color.lightGrey,
            2,
            1,
            255,
            true
    ),
    HeaderSmall = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.lightGrey,
            2,
            1,
            255,
            true
    ),
}

return TextStyle


