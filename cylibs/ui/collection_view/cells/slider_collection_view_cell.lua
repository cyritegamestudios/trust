local ImageView = require('cylibs/ui/image_view')

local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local Keyboard = require('cylibs/ui/input/keyboard')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local SliderCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
SliderCollectionViewCell.__index = SliderCollectionViewCell


function SliderCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), SliderCollectionViewCell)

    self.trackView = ImageCollectionViewCell.new(item:getTrackItem())
    self:addSubview(self.trackView)

    self.fillView = ImageCollectionViewCell.new(item:getFillItem())
    self:addSubview(self.fillView)

    self.counterView = TextCollectionViewCell.new(TextItem.new(tostring(item:getCurrentValue()), TextStyle.Default.TextSmall))
    self:addSubview(self.counterView)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function SliderCollectionViewCell:setSelected(selected)
    if not CollectionViewCell.setSelected(self, selected) then
        return false
    end

    if selected then
        self:requestFocus()
    else
        self:resignFocus()
    end
end

function SliderCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    self.trackView:setItem(item:getTrackItem())
    self.fillView:setItem(item:getFillItem())

    self.counterView:setItem(TextItem.new(item:getText(item:getCurrentValue()), TextStyle.Default.TextSmall))
    self.counterView:setPosition(self.trackView:getSize().width, -2)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function SliderCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    local percentage = (self:getItem():getCurrentValue() - self:getItem():getMinValue()) / (self:getItem():getMaxValue() - self:getItem():getMinValue())

    local width = percentage * (self:getItem():getTrackItem():getSize().width - 16)
    self.fillView:setSize(width, self.fillView:getSize().height)
    self.fillView:setPosition(8, 0)

    self.fillView:setNeedsLayout()
    self.fillView:layoutIfNeeded()

    return true
end

---
-- Checks if the specified coordinates are within the bounds of the view.
--
-- @tparam number x The x-coordinate to test.
-- @tparam number y The y-coordinate to test.
-- @treturn bool True if the coordinates are within the view's bounds, otherwise false.
--
function SliderCollectionViewCell:hitTest(x, y)
    return self.trackView:hitTest(x, y)
end

function SliderCollectionViewCell:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or CollectionViewCell.onKeyboardEvent(self, key, pressed, flags, blocked)
    if blocked then
        return true
    end
    if pressed then
        local key = Keyboard.input():getKey(key)
        if key then
            local currentValue = self:getItem():getCurrentValue()
            if key == 'Left' then
                local newValue = currentValue - self:getItem():getInterval()
                self:getItem():setCurrentValue(newValue)
                self:setItem(self:getItem())
                return true
            elseif key == 'Right' then
                local newValue = currentValue + self:getItem():getInterval()
                self:getItem():setCurrentValue(newValue)
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

function SliderCollectionViewCell:setHasFocus(hasFocus)
    CollectionViewCell.setHasFocus(self, hasFocus)

    self:layoutIfNeeded()

    if self:hasFocus() then
        self:setShouldResignFocus(false)
    end
end

return SliderCollectionViewCell