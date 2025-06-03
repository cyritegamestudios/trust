local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')
local Keyboard = require('cylibs/ui/input/keyboard')
local list_ext = require('cylibs/util/extensions/lists')
local Mouse = require('cylibs/ui/input/mouse')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIFastPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')

local PickerCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
PickerCollectionViewCell.__index = PickerCollectionViewCell
PickerCollectionViewCell.__type = "PickerCollectionViewCell"


function PickerCollectionViewCell.new(item, textStyle)
    textStyle = textStyle or TextStyle.Picker.TextSmall

    local self = setmetatable(CollectionViewCell.new(item), PickerCollectionViewCell)

    self.textStyle = textStyle

    local text = item:getTextFormat()(item:getCurrentValue())

    local textItem = TextItem.new(text, textStyle)
    textItem:setShouldTruncateText(item:getShouldTruncateText())

    self.textView = TextCollectionViewCell.new(textItem)
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

    self.textView:setSelected(selected)

    if not self:getItem():allowsMultipleSelection() then
        if selected then
            self:requestFocus()
        else
            self:resignFocus()
        end
    else
        if selected then
            self:showPickerView()
        end
    end
end

function PickerCollectionViewCell:setItem(item)
    CollectionViewCell.setItem(self, item)

    local text = item:getTextFormat()(item:getCurrentValue())

    local textItem = TextItem.new(text, self.textStyle)
    textItem:setShouldTruncateText(item:getShouldTruncateText())

    self.textView:setItem(textItem)

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

    self.textView:setSize(self:getSize().width, self:getSize().height)
    self.textView:layoutIfNeeded()

    return true
end

function PickerCollectionViewCell:hitTest(x, y)
    return self.textView:hitTest(x, y)
end

function PickerCollectionViewCell:showPickerView()
    local item = self:getItem()
    if item:allowsMultipleSelection() then
        local menuItem = MenuItem.new(L{
            ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
            ButtonItem.localized('Clear All', i18n.translate('Button_Clear_All')),
            ButtonItem.localized('Filter', i18n.translate('Button_Filter')),
        }, {}, function(_, _)
            local initialValue = item:getCurrentValue()
            if class(initialValue) ~= 'List' then
                initialValue = L{ initialValue }
            end
            
            local configItem = MultiPickerConfigItem.new("Items", initialValue, item:getAllValues(), function(value)
                return item:getPickerTextFormat()(value)
            end, nil, nil, item:getImageItemForText())

            local pickerView = FFXIPickerView.new(configItem)
            pickerView:setAllowsMultipleSelection(true)

            pickerView:on_pick_items():addAction(function(pickerView, selectedItems)
                self:getItem():setCurrentValue(selectedItems:map(function(item) return item end))
                self:setItem(self:getItem())

                self:getItem():getOnPickItems()(self:getItem():getCurrentValue())
            end)
            return pickerView
        end, item:getPickerTitle() or "Choose", item:getPickerDescription() or "Choose one or more values.")

        item:getShowMenu()(menuItem)
    end
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
                if self:getItem():allowsMultipleSelection() then
                    return false
                end
                local interval = 1
                if flags == 1 then
                    interval = 50
                end
                local newIndex = currentIndex - interval
                if newIndex < 1 then
                    newIndex = self:getItem():getAllValues():length()
                end
                local newValue = self:getItem():getAllValues()[newIndex]
                self:getItem():setCurrentValue(newValue)
                self:setItem(self:getItem())
                return true
            elseif key == 'Right' then
                if self:getItem():allowsMultipleSelection() then
                    return false
                end
                local interval = 1
                if flags == 1 then
                    interval = 50
                end
                local newIndex = currentIndex + interval
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

function PickerCollectionViewCell:onMouseEvent(type, x, y, delta)
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

function PickerCollectionViewCell:setHasFocus(hasFocus)
    if self:getItem():allowsMultipleSelection() then
        hasFocus = false
    end
    CollectionViewCell.setHasFocus(self, hasFocus)

    self:layoutIfNeeded()

    if self:hasFocus() then
        self:setShouldResignFocus(false)
    end
end

return PickerCollectionViewCell