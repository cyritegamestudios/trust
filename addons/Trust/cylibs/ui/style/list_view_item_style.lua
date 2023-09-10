---
-- @module ListViewItemStyle
--

local ListViewItemStyle = {}
ListViewItemStyle.__index = ListViewItemStyle

---
-- Creates a new ListViewItemStyle instance.
--
-- @tparam table selectedBackgroundColor The selected background color as {alpha, red, green, blue}.
-- @tparam table defaultBackgroundColor The default background color as {alpha, red, green, blue}.
-- @tparam string fontName The font name.
-- @tparam number fontSize The font size.
-- @tparam table fontColor The font color as {red, green, blue}.
-- @tparam table highlightColor The highlighted font color as {red, green, blue}.
-- @tparam number padding The padding on each side.
-- @tparam number strokeWidth The stroke width.
-- @tparam number strokeAlpha The stroke alpha.
-- @tparam boolean bold Whether the text should be bolded.
-- @treturn ListViewItemStyle The newly created ListViewItemStyle instance.
--
function ListViewItemStyle.new(selectedBackgroundColor, defaultBackgroundColor, fontName, fontSize, fontColor, highlightColor, padding, strokeWidth, strokeAlpha, bold)
    local self = setmetatable({}, ListViewItemStyle)
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
-- @treturn table The selected background color as {a, r, g, b}.
--
function ListViewItemStyle:getSelectedBackgroundColor()
    return self.selectedBackgroundColor
end

---
-- Gets the default background color.
--
-- @treturn table The default background color as {a, r, g, b}.
--
function ListViewItemStyle:getDefaultBackgroundColor()
    return self.defaultBackgroundColor
end

---
-- Gets the font name.
--
-- @treturn string The font name.
--
function ListViewItemStyle:getFontName()
    return self.fontName
end

---
-- Gets the font size.
--
-- @treturn number The font size.
--
function ListViewItemStyle:getFontSize()
    return self.fontSize
end

---
-- Gets the font color.
--
-- @treturn table The font color as {red, green, blue}.
--
function ListViewItemStyle:getFontColor()
    return self.fontColor
end

---
-- Gets the highlighted font color.
--
-- @treturn table The font color as {red, green, blue}.
--
function ListViewItemStyle:getHighlightColor()
    return self.highlightColor
end

---
-- Gets the padding.
--
-- @treturn number The padding.
--
function ListViewItemStyle:getPadding()
    return self.padding
end

---
-- Gets the stroke width.
--
-- @treturn number The stroke width.
--
function ListViewItemStyle:getStrokeWidth()
    return self.strokeWidth
end

---
-- Gets the stroke alpha.
--
-- @treturn number The stroke alpha.
--
function ListViewItemStyle:getStrokeAlpha()
    return self.strokeAlpha
end

---
-- Gets the value of bold.
--
-- @treturn boolean Value of bold.
--
function ListViewItemStyle:isBold()
    return self.bold
end


ListViewItemStyle.TextColor = {
    Red = {red = 255, green = 132, blue = 132}
}

ListViewItemStyle.LightMode = {
    -- Default style for headers in light mode
    Header = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            14,
            {red = 40, green = 40, blue = 40},
            {red = 40, green = 40, blue = 40},
            2,
            2,
            150,
            true
    ),
    -- Default style for text in light mode
    Text = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            12,
            {red = 80, green = 80, blue = 80},
            {red = 80, green = 80, blue = 80},
            2,
            0,
            0,
            false
    )
}

ListViewItemStyle.DarkMode = {
    -- Default style for headers in dark mode
    Header = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            14,
            {red = 255, green = 255, blue = 255},
            {red = 205, green = 205, blue = 205},
            2,
            2,
            150,
            true
    ),
    HeaderSmall = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            10,
            {red = 255, green = 255, blue = 255},
            {red = 205, green = 205, blue = 205},
            2,
            2,
            150,
            true
    ),
    -- Style for red headers in dark mode
    HeaderRed = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            14,
            ListViewItemStyle.TextColor.Red,
            {red = 205, green = 205, blue = 205},
            2,
            2,
            150,
            true
    ),
    -- Default style for text in dark mode
    Text = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            12,
            {red = 255, green = 255, blue = 255},
            {red = 255, green = 255, blue = 255},
            2,
            0,
            0,
            false
    ),
    -- Small style for text in dark mode
    TextSmall = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            10,
            {red = 255, green = 255, blue = 255},
            {red = 205, green = 205, blue = 205},
            2,
            0,
            0,
            false
    ),
    TextSmallBold = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            10,
            {red = 255, green = 255, blue = 255},
            {red = 205, green = 205, blue = 205},
            2,
            0,
            0,
            true
    ),
    -- Default style for highlighted text in dark mode
    HighlightedText = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            12,
            {red = 0, green = 255, blue = 0},
            {red = 0, green = 255, blue = 0},
            2,
            0,
            0,
            false
    ),
    -- Default style for images
    Image = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            12,
            {red = 0, green = 0, blue = 0},
            {red = 0, green = 0, blue = 0},
            2,
            0,
            0,
            true
    ),
    Button = ListViewItemStyle.new(
            {alpha = 0, red = 0, green = 0, blue = 0},
            {alpha = 0, red = 0, green = 0, blue = 0},
            "Arial",
            12,
            {red = 255, green = 255, blue = 255},
            {red = 205, green = 205, blue = 205},
            2,
            2,
            150,
            true
    ),
}

return ListViewItemStyle


