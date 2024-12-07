local Alignment = require('cylibs/ui/layout/alignment')
local localization_util = require('cylibs/util/localization_util')
local texts = require('texts')

local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')

local TextCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
TextCollectionViewCell.__index = TextCollectionViewCell
TextCollectionViewCell.__type = "TextCollectionViewCell"

---
-- Creates a new CollectionViewCell.
--
-- @tparam TextItem item The item associated with the cell.
-- @treturn CollectionViewCell The newly created cell.
--
function TextCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), TextCollectionViewCell)

    self.textView = texts.new(item:getPattern(), item:getSettings())
    self.textView:bg_alpha(0)
    self.textView:hide()

    self:getDisposeBag():addAny(L{ self.textView })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function TextCollectionViewCell:destroy()
    CollectionViewCell.destroy(self)
end

function TextCollectionViewCell:applyTextStyle()
    local style = self:getItem():getStyle()
    if self:isSelected() then
        self:setTextColor(style:getSelectedColor())
        self.textView:bold(true)
    elseif self:isHighlighted() then
        self:setTextColor(style:getHighlightColor())
        self.textView:bold(style:isBold())
    else
        self:setTextColor(style:getFontColor())
        self.textView:bold(style:isBold())
    end
    self.textView:italic(style:isItalic())
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function TextCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) or self.superview == nil then
        return false
    end

    local isVisible = self:getAbsoluteVisibility() and self:isVisible()
    if isVisible then
        local position = self:getAbsolutePosition()

        local text = self:getItem():getLocalizedText()
        if self:getItem():shouldTruncateText() then
            text = localization_util.truncate(text, math.floor(self:getSize().width / (self:getItem():getStyle():getFontSize() * 0.75)))
        end
        self.textView.text = text

        local textWidth
        if self:getItem():getSize() then
            textWidth = self:getItem():getSize().width
        else
            textWidth = string.len(self:getItem():getLocalizedText()) * self:getItem():getStyle():getFontSize()
        end

        if self:getItem():shouldAutoResize() then
            if textWidth > self:getSize().width + 10 then
                self.textView:size(self:getItem():getStyle():getFontSize() - 1)
            else
                self.textView:size(self:getItem():getStyle():getFontSize())
            end
        end
        if self:getItem():shouldWordWrap() then
            if textWidth > self:getSize().width + 12 then
                local text = ""
                local words = self:getItem():getLocalizedText():split(" ")
                for word in words:it() do
                    text = text..word.."\n "
                end
                self.textView.text = text
            end
        end

        local textPosX = position.x + self:getItem():getOffset().x
        if self:getItem():getHorizontalAlignment() == Alignment.center() then
            textPosX = textPosX + (self:getSize().width - textWidth) / 4
        end

        local textPosY = position.y + (self:getSize().height - self:getEstimatedSize() * (self.textView:size() / self:getItem():getStyle():getFontSize())) / 2 + self:getItem():getOffset().y
        self.textView:pos(textPosX, textPosY)

        self:applyTextStyle()

        if self:getItem():getEnabled() then
            self.textView:alpha(255)
        else
            self.textView:alpha(150)
        end
    end

    self.textView:visible(isVisible)

    return true
end

function TextCollectionViewCell:setHighlighted(highlighted)
    if highlighted then
        self:setTextColor(self:getItem():getStyle():getHighlightColor())
    else
        self:setTextColor(self:getItem():getStyle():getFontColor())
    end
    CollectionViewCell.setHighlighted(self, highlighted)
end

function TextCollectionViewCell:setSelected(selected)
    if selected then
        self:setTextColor(self:getItem():getStyle():getSelectedColor())
    else
        self:setTextColor(self:getItem():getStyle():getFontColor())
    end
    CollectionViewCell.setSelected(self, selected)
end

---
-- Sets the text color of the TextCollectionViewCell's text view.
--
-- @tparam Color color The color to set.
--
function TextCollectionViewCell:setTextColor(color)
    self.textView:alpha(color.alpha)
    self.textView:color(color.red, color.green, color.blue)
end

function TextCollectionViewCell:setAlpha(alpha)
    self.textView:alpha(alpha)
end

---
-- Sets the item associated with the cell.
--
-- @tparam any item The item to associate with the cell.
--
function TextCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    self.textView:font(self:getItem():getSettings().text.font)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function TextCollectionViewCell:hitTest(x, y)
    return self.textView:hover(x, y)
end

return TextCollectionViewCell