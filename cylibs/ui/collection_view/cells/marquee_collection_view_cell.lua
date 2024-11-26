local Alignment = require('cylibs/ui/layout/alignment')
local DisposeBag = require('cylibs/events/dispose_bag')
local texts = require('texts')
local Timer = require('cylibs/util/timers/timer')

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
function MarqueeCollectionViewCell.new(item, multiplier)
    local self = setmetatable(TextCollectionViewCell.new(item), MarqueeCollectionViewCell)

    self.multiplier = multiplier or 1
    self.currentIndex = -1
    self.numCharacters = 10
    self.currentText = self:getItem():getText()
    self.timer = Timer.scheduledTimer(0.125, 0.5)
    self.disposeBag = DisposeBag.new()

    self.disposeBag:add(self.timer:onTimeChange():addAction(function(_)
        self:nextFrame()
    end), self.timer:onTimeChange())

    self.disposeBag:addAny(L{ self.timer })

    return self
end

function MarqueeCollectionViewCell:destroy()
    TextCollectionViewCell.destroy(self)

    self.disposeBag:destroy()
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
    local multiplier = self.multiplier
    if self:getItem():getStyle():isBold() then
        multiplier = multiplier * 1.2
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

    if item:getText():length() > self.numCharacters then
        self:setAnimated(self:isVisible())
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

function MarqueeCollectionViewCell:setAnimated(animated)
    if self.timer:isRunning() == animated then
        return
    end
    if animated then
        self.timer:start()
    else
        self.timer:cancel()
    end
end

function MarqueeCollectionViewCell:updateText()
    local text = self:getItem():getLocalizedText()
    if text:length() > self.numCharacters then
        if text:length() >= self.currentIndex + self.numCharacters then
            local next = text:slice(self.currentIndex, math.min(self.currentIndex + self.numCharacters + 3, text:length()))
            if next:startswith('→') or next:endswith('→') then
                self.currentIndex = (self.currentIndex + 3 + 1) % text:length()
            else
                self.currentIndex = (self.currentIndex + 1) % text:length()
            end

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
    if not self.timer:isRunning() or not self:isVisible() then
        return
    end
    self:updateText()
end

return MarqueeCollectionViewCell