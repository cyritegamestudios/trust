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
    self.coroutines = L{}

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
    self:updateNumCharacters()
end

function MarqueeCollectionViewCell:setVisible(visible)
    TextCollectionViewCell.setVisible(self, visible)

    self:updateText()
end

function MarqueeCollectionViewCell:updateNumCharacters()
    local multiplier = 1
    if self:getItem():getStyle():isBold() then
        multiplier = 1.2
    end
    self.numCharacters = math.floor(self:getSize().width / (self:getItem():getStyle():getFontSize() * multiplier) + 6)
end

function MarqueeCollectionViewCell:setItem(item)
    if item == self.item then
        return
    end
    self:setAnimated(false)

    TextCollectionViewCell.setItem(self, item)

    self.currentIndex = -1

    self:updateNumCharacters()
    self:updateText()

    if item:getText():length() > 0 then
        self:setAnimated(self:isVisible(), 1.0)
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
        self.coroutines:append(coroutine.schedule(function()
            self:nextFrame()
        end, delay or 0.1))
    else
        for id in self.coroutines:it() do
            coroutine.close(id)
        end
        self.coroutines = L{}
    end
end

function MarqueeCollectionViewCell:updateText()
    local text = self:getItem():getText()
    if text:length() > self.numCharacters then
        if text:length() >= self.currentIndex + self.numCharacters then
            local next = text:slice(self.currentIndex, math.min(self.currentIndex + self.numCharacters + 3, text:length()))
            --local start_index, end_index = text:slice(self.currentIndex):find('→')
            if next:startswith('→') or next:endswith('→') then
                self.currentIndex = (self.currentIndex + 3 + 1) % text:length()
            else
                self.currentIndex = (self.currentIndex + 1) % text:length()
            end

            --[[if self.currentText:startswith('→') then
                local start_index, end_index = self.currentText:find('→')
                self.currentIndex = (self.currentIndex + end_index - start_index + 1) % text:length()
            else
                self.currentIndex = (self.currentIndex + 1) % text:length()
            end]]
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
        self.coroutines:append(coroutine.schedule(function() self:nextFrame()  end, 0.25))
    end
end

return MarqueeCollectionViewCell