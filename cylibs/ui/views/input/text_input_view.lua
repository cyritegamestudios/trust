local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Event = require('cylibs/events/Luvent')
local FFXITextFieldItem = require('ui/themes/FFXI/FFXITextFieldItem')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextFieldCollectionViewCell = require('cylibs/ui/collection_view/cells/text_field_collection_view_cell')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local TextInputView = setmetatable({}, {__index = CollectionView })
TextInputView.__index = TextInputView

-- Event called when text is input.
function TextInputView:onTextChanged()
    return self.textChanged
end

function TextInputView.new(placeholderText)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        local cell = TextFieldCollectionViewCell.new(item)
        cell:setItemSize(32)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(6, Padding.new(15, 16, 0, 0), 0)), TextInputView)

    self:setAllowsCursorSelection(false)
    self:setScrollDelta(32)

    self.placeholderText = placeholderText
    self.textChanged = Event.newEvent()

    self:reloadSettings()

    self:setVisible(false)
    self:setAllowsCursorSelection(false)

    self:getDelegate():deselectAllItems()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function TextInputView:destroy()
    CollectionView.destroy(self)
end


function TextInputView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Confirm' then
        local item = self:getDataSource():itemAtIndexPath(IndexPath.new(1, 1))
        if item then
            self:onTextChanged():trigger(self, item:getTextItem():getText():gsub('|', ''))
        end
    end
end

function TextInputView:setVisible(visible)
    if not CollectionView.setVisible(self, visible) then
        return false
    end

    if visible then
        self:reloadSettings()

        self:setNeedsLayout()
        self:layoutIfNeeded()
    end

    return true
end

function TextInputView:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1

    local textFields = L{
        FFXITextFieldItem.new(self.placeholderText),
    }

    for textField in textFields:it() do
        items:append(IndexedItem.new(textField, IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
end

function TextInputView:setHasFocus(hasFocus)
    CollectionView.setHasFocus(self, hasFocus)

    if not self:hasFocus() then
        self:getDelegate():deselectAllItems()
    end
end

return TextInputView