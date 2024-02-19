local Alignment = require('cylibs/ui/layout/alignment')
local texts = require('texts')

local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')

local MarqueeCollectionViewCell = setmetatable({}, {__index = TextCollectionViewCell })
MarqueeCollectionViewCell.__index = MarqueeCollectionViewCell
MarqueeCollectionViewCell.__type = "MarqueeCollectionViewCell"

---
-- Creates a new CollectionViewCell.
--
-- @tparam TextItem item The item associated with the cell.
-- @treturn CollectionViewCell The newly created cell.
--
function MarqueeCollectionViewCell.new(item)
    local self = setmetatable(TextCollectionViewCell.new(item), MarqueeCollectionViewCell)

    self.currentIndex = -1
    self.numCharacters = 10
    self.currentText = self:getItem():getText()

    return self
end

---
-- Sets the size of the view.
--
-- @tparam number width The width to set.
-- @tparam number height The height to set.
--
function MarqueeCollectionViewCell:setSize(width, height)
    TextCollectionViewCell.setSize(self, width, height)

    self.currentIndex = -1
    self.numCharacters = width / self:getItem():getStyle():getFontSize() + 6
end

function MarqueeCollectionViewCell:setVisible(visible)
    TextCollectionViewCell.setVisible(self, visible)

    self:updateText()

    --self:setAnimated(self:isVisible(), 0.1)
end

function MarqueeCollectionViewCell:setItem(item)
    if item == self.item then
        return
    end
    TextCollectionViewCell.setItem(self, item)

    self.currentIndex = -1
    self.numCharacters = self:getSize().width / item:getStyle():getFontSize() + 6

    self:updateText()

    if item:getText():length() > 0 then
        self:setAnimated(self:isVisible(), 0.5)
    else
        self:setAnimated(false)
    end
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function MarqueeCollectionViewCell:layoutIfNeeded()
    if self.superview == nil then
        return false
    end

    self.textView.text = self.currentText
    self.textView:size(self:getItem():getStyle():getFontSize())

    self:applyTextStyle()

    local position = self:getAbsolutePosition()

    local textPosX = position.x + self:getItem():getOffset().x
    local textPosY = position.y + (self:getSize().height - self:getEstimatedSize() * (self.textView:size() / self:getItem():getStyle():getFontSize())) / 2 + self:getItem():getOffset().y

    self.textView:pos(textPosX, textPosY)

    self.textView:visible(self:getAbsoluteVisibility() and self:isVisible())

    return true
end

function MarqueeCollectionViewCell:setAnimated(animated, delay)
    if self.animated == animated then
        return
    end
    self.animated = animated

    if self.animated then
        coroutine.schedule(function()
            self:nextFrame()
        end, delay or 0.1)
    end
end

function MarqueeCollectionViewCell:updateText()
    local text = self:getItem():getText()
    if text:length() > self.numCharacters then
        if text:length() >= self.currentIndex + self.numCharacters then
            self.currentIndex = (self.currentIndex + 1) % text:length()
            self.currentText = text:slice(self.currentIndex, math.min(self.currentIndex + self.numCharacters, text:length()))

            self:setNeedsLayout()
            self:layoutIfNeeded()

            return true
        end
    else
        self.currentText = text
    end
    return false
end

function MarqueeCollectionViewCell:nextFrame()
    if not self.animated or not self:isVisible() then
        return
    end

    if self:updateText() then
        coroutine.schedule(function() self:nextFrame()  end, 0.25)
    end
end

return MarqueeCollectionViewCell