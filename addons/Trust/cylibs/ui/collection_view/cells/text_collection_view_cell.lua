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

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function TextCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) or self.superview == nil then
        return false
    end

    local position = self:getAbsolutePosition()

    self.textView.text = self:getItem():getText()
    self.textView:pos(position.x, position.y + (self:getSize().height - self:getEstimatedSize()) / 2)

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

    self.textView:visible(self:getAbsoluteVisibility() and self:isVisible())

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

---
-- Sets the item associated with the cell.
--
-- @tparam any item The item to associate with the cell.
--
function TextCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)
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