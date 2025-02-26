local Color = require('cylibs/ui/views/color')
local i18n = require('cylibs/i18n/i18n')

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
-- @tparam Color strokeColor The stroke color.
-- @tparam boolean bold Whether the text should be bolded.
-- @tparam Color selectedColor The selected font color.
-- @tparam Color cursorColor The color when the cursor is next to the text.
-- @treturn TextStyle The newly created TextStyle instance.
--
function TextStyle.new(selectedBackgroundColor, defaultBackgroundColor, fontName, fontSize, fontColor, highlightColor, padding, strokeWidth, strokeColor, bold, selectedColor, italic)
    local self = setmetatable({}, TextStyle)

    self.selectedBackgroundColor = selectedBackgroundColor
    self.defaultBackgroundColor = defaultBackgroundColor
    self.fontName = fontName
    self.fontSize = fontSize
    self.fontColor = fontColor
    self.highlightColor = highlightColor
    self.padding = padding
    self.strokeWidth = strokeWidth
    self.strokeColor = strokeColor or Color.clear
    self.bold = bold
    self.selectedColor = selectedColor or self.fontColor
    self.italic = italic
    self.highlightBold = false

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
    return i18n.font_for_locale(i18n.current_locale()) or self.fontName
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
-- Gets the selected font color.
--
-- @treturn Color The font color.
--
function TextStyle:getSelectedColor()
    return self.selectedColor
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
    return self.strokeColor.alpha
end

---
-- Gets the stroke color.
--
-- @treturn Color The stroke color.
--
function TextStyle:getStrokeColor()
    return self.strokeColor
end

---
-- Gets the value of bold.
--
-- @treturn boolean Value of bold.
--
function TextStyle:isBold()
    return self.bold
end

---
-- Gets the value of highlightBold.
--
-- @treturn boolean Value of highlightBold.
--
function TextStyle:isHighlightBold()
    return self.highlightBold
end

---
-- Gets the value of italic.
--
-- @treturn boolean Value of italic.
--
function TextStyle:isItalic()
    return self.italic
end

---
-- Estimated width of the given text.
--
-- @tparam string text Text
--
-- @treturn number Estimated width of the text.
--
function TextStyle:getEstimatedTextWidth(text)
    local textWidth = self:getFontSize() * text:length()
    if self:isBold() then
        textWidth = textWidth * 1.05
    end
    return textWidth
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
            Color.clear,
            false,
            Color.yellow
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
            Color.clear,
            false,
            Color.yellow
    ),
    TextExtraSmall = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            6,
            Color.white,
            Color.lightGrey,
            2,
            0,
            Color.clear,
            false,
            Color.yellow
    ),
    Subheadline = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            8,
            Color.white,
            Color.lightGrey,
            2,
            0,
            Color.clear,
            false,
            Color.yellow
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
            Color.black,
            true
    ),
    ButtonSmall = TextStyle.new(
            Color.lightGrey:withAlpha(50),
            Color.clear,
            "Arial",
            10,
            Color.white:withAlpha(225),
            Color.lightGrey,
            0,
            0.5,
            Color.new(175, 150, 150, 150),
            true
    ),
    HeaderSmall = TextStyle.new(
            Color.yellow,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.lightGrey,
            2,
            1,
            Color.black,
            true,
            Color.yellow
    ),
    NavigationTitle = TextStyle.new(
            Color.clear,
            Color.white:withAlpha(50),
            "Arial",
            11,
            Color.white,
            Color.lightGrey,
            2,
            1,
            Color.black,
            true
    ),
    SectionHeader = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            10,
            Color.white,
            Color.lightGrey,
            0,
            0,
            Color.clear,
            true,
            Color.white,
            true
    ),
    PickerItem = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.pink,
            0,
            0,
            Color.clear,
            true,
            Color.yellow
    ),
}

TextStyle.Picker = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.pink,
            0,
            0,
            Color.clear,
            true,
            Color.yellow
    ),
    TextSmall = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            10,
            Color.white,
            Color.pink,
            0,
            0,
            Color.clear,
            false,
            Color.yellow
    ),
}

TextStyle.ConfigEditor = {
    TextSmall = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            10,
            Color.white,
            Color.pink,
            0,
            0,
            Color.clear,
            false,
            Color.yellow
    ),
}

return TextStyle


