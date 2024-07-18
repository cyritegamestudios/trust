local ImageView = require('cylibs/ui/image_view')

local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local Keyboard = require('cylibs/ui/input/keyboard')
local list_ext = require('cylibs/util/extensions/lists')
local PickerItem = require('cylibs/ui/collection_view/items/picker_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local PickerCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
PickerCollectionViewCell.__index = PickerCollectionViewCell
PickerCollectionViewCell.__type = "PickerCollectionViewCell"


function PickerCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), PickerCollectionViewCell)

    self.textView = TextCollectionViewCell.new(TextItem.new(item:getTextFormat()(item:getCurrentValue()), TextStyle.Default.TextSmall))
    self:addSubview(self.textView)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Sets the selection state of the cell.
-- @tparam boolean selected The new selection state.
--
function PickerCollectionViewCell:setSelected(selected)
    if not CollectionViewCell.setSelected(self, selected) then
        return false
    end

    if selected then
        self:requestFocus()
    else
        self:resignFocus()
    end
end

function PickerCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    self.textView:setItem(TextItem.new(item:getTextFormat()(item:getCurrentValue()), TextStyle.Default.TextSmall))

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function PickerCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    return true
end

function PickerCollectionViewCell:hitTest(x, y)
    return self.textView:hitTest(x, y)
end

function PickerCollectionViewCell:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or CollectionViewCell.onKeyboardEvent(self, key, pressed, flags, blocked)
    if blocked then
        return true
    end
    if pressed then
        local key = Keyboard.input():getKey(key)
        if key then
            local currentIndex = self:getItem():getAllValues():indexOf(self:getItem():getCurrentValue())
            if key == 'Left' then
                local newIndex = currentIndex - 1
                if newIndex < 1 then
                    newIndex = self:getItem():getAllValues():length()
                end
                local newValue = self:getItem():getAllValues()[newIndex]
                self:getItem():setCurrentValue(newValue)
                self:setItem(self:getItem())
                return true
            elseif key == 'Right' then
                local newIndex = currentIndex + 1
                if newIndex > self:getItem():getAllValues():length() then
                    newIndex = 1
                end
                local newValue = self:getItem():getAllValues()[newIndex]
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

function PickerCollectionViewCell:setHasFocus(hasFocus)
    CollectionViewCell.setHasFocus(self, hasFocus)

    self:layoutIfNeeded()

    if self:hasFocus() then
        self:setShouldResignFocus(false)
    end
end

return PickerCollectionViewCell