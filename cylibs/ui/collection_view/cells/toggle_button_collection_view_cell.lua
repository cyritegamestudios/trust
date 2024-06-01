local ToggleButtonItem = require('cylibs/ui/collection_view/items/toggle_button_item')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local DisposeBag = require('cylibs/events/dispose_bag')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')

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

    if self:getItem():getEnabled() then
        self:setSelected(true)
    else
        self:setSelected(false)
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

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

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function ToggleButtonCollectionViewCell:setSelected(selected)
    if selected == self.selected then
        return false
    end

    if selected then
        self:getItem():setEnabled(true)
        self:setButtonState(ToggleButtonItem.State.Enabled)
    else
        self:getItem():setEnabled(false)
        self:setButtonState(ToggleButtonItem.State.Disabled)
    end

    CollectionViewCell.setSelected(self, selected)

    return true
end

return ToggleButtonCollectionViewCell