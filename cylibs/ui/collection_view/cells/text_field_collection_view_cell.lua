local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local Keyboard = require('cylibs/ui/input/keyboard')

local TextFieldCollectionViewCell = setmetatable({}, {__index = ButtonCollectionViewCell })
TextFieldCollectionViewCell.__index = TextFieldCollectionViewCell


function TextFieldCollectionViewCell.new(textFieldItem)
    local self = setmetatable(ButtonCollectionViewCell.new(textFieldItem), TextFieldCollectionViewCell)

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

function TextFieldCollectionViewCell:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or ButtonCollectionViewCell.onKeyboardEvent(self, key, pressed, flags, blocked)
    if blocked then
        return true
    end
    if pressed then
        local key = Keyboard.input():getKey(key, flags)
        if key then
            local textItem = self:getItem():getTextItem()
            if textItem and not self:getKeyBlacklist():contains(key) then
                local currentText = textItem:getText():gsub('|', '')
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
                    textItem:setText(newText..'|')
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
    return S{ 'Left', 'Right', 'Escape', 'LShift', 'RRhift' }
end

function TextFieldCollectionViewCell:setCursorVisible(cursorVisible)
    local isCursorVisible = self:getItem():getTextItem():getText():endswith('|')
    if isCursorVisible == cursorVisible then
        return
    end

    local textItem = self:getItem():getTextItem()
    if cursorVisible then
        textItem:setText(textItem:getText()..'|')
    else
        textItem:setText(textItem:getText():gsub('|', ''))
    end

    self:setNeedsLayout()
end

function TextFieldCollectionViewCell:setHasFocus(hasFocus)
    ButtonCollectionViewCell.setHasFocus(self, hasFocus)

    self:setCursorVisible(hasFocus)

    self:layoutIfNeeded()

    Keyboard.input():setActive(self:hasFocus())

    --[[local keys = L{'a','w','s','d','f','e','h','i','k','l','y','lshift','-'}
    for key in keys:it() do
        if self:hasFocus() then
            windower.send_command('bind %s block':format(key))
        else
            windower.send_command('unbind %s':format(key))
        end
    end]]
end

return TextFieldCollectionViewCell