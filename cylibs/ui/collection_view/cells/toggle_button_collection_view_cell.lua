local Keyboard = require('cylibs/ui/input/keyboard')
local ToggleButtonItem = require('cylibs/ui/collection_view/items/toggle_button_item')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local DisposeBag = require('cylibs/events/dispose_bag')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local Mouse = require('cylibs/ui/input/mouse')

local ToggleButtonCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ToggleButtonCollectionViewCell.__index = ToggleButtonCollectionViewCell


function ToggleButtonCollectionViewCell.new(buttonItem)
    local self = setmetatable(CollectionViewCell.new(buttonItem), ToggleButtonCollectionViewCell)

    self.buttonState = nil
    self.backgroundViews = {}
    self.disposeBag = DisposeBag.new()

    self:setSize(buttonItem:getSize().width, buttonItem:getSize().height)

    if buttonItem:getEnabled() then
        self.buttonView = ImageCollectionViewCell.new(buttonItem:getImageItem(ToggleButtonItem.State.Enabled))
    else
        self.buttonView = ImageCollectionViewCell.new(buttonItem:getImageItem(ToggleButtonItem.State.Disabled))
    end

    self:addSubview(self.buttonView)

    return self
end

function ToggleButtonCollectionViewCell:destroy()
    CollectionViewCell.destroy(self)

    self.disposeBag:destroy()
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ToggleButtonCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    return true
end

---
-- Sets the button state of the cell.
-- @tparam ToggleButtonItem.State buttonState The new button state.
--
function ToggleButtonCollectionViewCell:setButtonState(buttonState)
    if self.buttonState == buttonState then
        return
    end
    self.buttonState = buttonState

    local imageItem = self:getItem():getImageItem(buttonState)
    if imageItem then
        self.buttonView:setItem(imageItem)
        self.buttonView:setNeedsLayout()
        self.buttonView:layoutIfNeeded()
    end
end

function ToggleButtonCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    if item:getEnabled() then
        self:setButtonState(ToggleButtonItem.State.Enabled)
    else
        self:setButtonState(ToggleButtonItem.State.Disabled)
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function ToggleButtonCollectionViewCell:setSelected(selected)
    if not CollectionViewCell.setSelected(self, selected) then
        return false
    end

    if selected then
        self:requestFocus()
    else
        self:resignFocus()
    end

    return true
end

function ToggleButtonCollectionViewCell:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or CollectionViewCell.onKeyboardEvent(self, key, pressed, flags, blocked)
    if blocked then
        return true
    end
    if pressed then
        local key = Keyboard.input():getKey(key)
        if key then
            if L{ 'Left', 'Right' }:contains(key) then
                local enabled = not self:getItem():getEnabled()
                self:getItem():setEnabled(enabled)
                self:setItem(self:getItem())
                return true
            elseif key == 'Escape' then
                self:setShouldResignFocus(true)
                self:resignFocus()
            end
        end
    end
    return false
end

function ToggleButtonCollectionViewCell:onMouseEvent(type, x, y, delta)
    if type == Mouse.Event.ClickRelease then
        if self:hasFocus() then
            self:setShouldResignFocus(true)
            self:resignFocus()
            self:setSelected(false)
            return true
        end
    elseif type == Mouse.Event.Wheel then
        if self:hasFocus() then
            self:onKeyboardEvent(205, true, 0, false)
            return true
        end
    end
    return false
end

function ToggleButtonCollectionViewCell:setHasFocus(hasFocus)
    CollectionViewCell.setHasFocus(self, hasFocus)

    self:layoutIfNeeded()

    if self:hasFocus() then
        self:setShouldResignFocus(false)
    end
end

return ToggleButtonCollectionViewCell