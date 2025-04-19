local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local Keyboard = require('cylibs/ui/input/keyboard')
local Timer = require('cylibs/util/timers/timer')
local texts = require('texts')

local TextFieldCollectionViewCell = setmetatable({}, {__index = ButtonCollectionViewCell })
TextFieldCollectionViewCell.__index = TextFieldCollectionViewCell


function TextFieldCollectionViewCell.new(textFieldItem)
    local self = setmetatable(ButtonCollectionViewCell.new(textFieldItem), TextFieldCollectionViewCell)

    self.lastCursorUpdate = os.clock()

    self.cursorTextView = texts.new("|", textFieldItem:getTextItem():getSettings())
    self.cursorTextView:bg_alpha(0)
    self.cursorTextView:hide()

    self.cursorTimer = Timer.scheduledTimer(0.05)
    self.disposeBag:add(self.cursorTimer:onTimeChange():addAction(function(_)
        self:updateCursor()
    end), self.cursorTimer:onTimeChange())

    self:getDisposeBag():addAny(L{ self.cursorTextView, self.cursorTimer })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function TextFieldCollectionViewCell:setSelected(selected)
    if not ButtonCollectionViewCell.setSelected(self, selected) then
        return false
    end

    if selected then
        self:requestFocus()
    else
        self:resignFocus()
    end
end

function TextFieldCollectionViewCell:updateCursor()
    if self:hasFocus() then
        local textView = self.textView.textView

        self.cursorTextView:pos(textView:pos_x() + textView:extents(), textView:pos_y() - 1)
        self.cursorTextView:visible(textView:visible())

        if os.clock() - self.lastCursorUpdate >= 0.5 then
            self.lastCursorUpdate = os.clock()
            local alpha = self.cursorTextView:alpha()
            if alpha == 255 then
                alpha = 0
            else
                alpha = 255
            end
            self.cursorTextView:alpha(alpha)
        end
    else
        self.cursorTextView:hide()
    end
end

function TextFieldCollectionViewCell:onKeyboardEvent(key, pressed, flags, blocked, resolved_key)
    local blocked = blocked or ButtonCollectionViewCell.onKeyboardEvent(self, key, pressed, flags, blocked, resolved_key)
    if blocked then
        return true
    end
    if pressed then
        local key = Keyboard.input():getKey(key, flags)
        if key then
            local textItem = self:getItem():getTextItem()
            if textItem and not self:getKeyBlacklist():contains(key) then
                local currentText = textItem:getText()
                local newText
                if key == "Backspace" then
                    newText = currentText:slice(1, currentText:length()-1)
                elseif key == "Escape" then
                    newText = currentText
                elseif not S{ 'LShift', 'RShift' }:contains(key) then
                    local nextChar = key:lower()
                    if flags == 1 then
                        nextChar = nextChar:ucfirst()
                    end
                    newText = (currentText..nextChar):ucfirst()
                else
                    newText = currentText
                end
                if self:getItem():isValid(newText) then
                    textItem:setText(newText)
                    self:setNeedsLayout()
                    self:layoutIfNeeded()
                end
            end
        end
        return true
    end
    return true
end

function TextFieldCollectionViewCell:getKeyBlacklist()
    return S{ 'Left', 'Right', 'Escape', 'LShift', 'RRhift', 'Enter' }
end

function TextFieldCollectionViewCell:setCursorVisible(cursorVisible)
    if cursorVisible then
        self.cursorTimer:resume()
    else
        self.cursorTimer:pause()
        self.cursorTextView:hide()
        self.cursorTextView:alpha(255)
    end
    self:updateCursor(999)
end

function TextFieldCollectionViewCell:setHasFocus(hasFocus)
    ButtonCollectionViewCell.setHasFocus(self, hasFocus)

    self:setCursorVisible(hasFocus)

    self:layoutIfNeeded()

    Keyboard.input():setActive(self:hasFocus())
end

return TextFieldCollectionViewCell