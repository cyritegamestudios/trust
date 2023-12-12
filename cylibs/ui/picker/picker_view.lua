local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local PickerView = setmetatable({}, {__index = CollectionView })
PickerView.__index = PickerView

TextStyle.PickerView = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            10,
            Color.white,
            Color.lightGrey,
            2,
            0,
            0,
            false,
            Color.yellow
    ),
}

---
-- Creates a new PickerView.
--
-- @tparam list pickerItems A list of PickerItems.
-- @tparam boolean allowsMultipleSelection Indicates if multiple selection is allowed.
-- @tparam ImageItem cursorImageItem (optional) The cursor image item
-- @treturn PickerView The created PickerView.
--
function PickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(15, 10, 0, 0)), nil, cursorImageItem), PickerView)

    self:setAllowsMultipleSelection(allowsMultipleSelection)
    self:setScrollDelta(20)

    local indexedItems = L{}
    local selectedIndexedItems = L{}

    local rowIndex = 1
    for pickerItem in pickerItems:it() do
        local indexedItem = IndexedItem.new(pickerItem:getItem(), IndexPath.new(1, rowIndex))
        indexedItems:append(indexedItem)
        if pickerItem:isSelected() then
            selectedIndexedItems:append(indexedItem)
        end
        rowIndex = rowIndex + 1
    end

    dataSource:addItems(indexedItems)

    for indexedItem in selectedIndexedItems:it() do
        self:getDelegate():selectItemAtIndexPath(indexedItem:getIndexPath())
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

---
-- Creates a new PickerView with text items.
--
-- @tparam list texts A list of text strings.
-- @tparam list selectedTexts A list of selected text strings.
-- @tparam boolean allowsMultipleSelection Indicates if multiple selection is allowed.
-- @tparam ImageItem cursorImageItem (optional) The cursor image item
-- @treturn PickerView The created PickerView.
--
function PickerView.withItems(texts, selectedTexts, allowsMultipleSelection, cursorImageItem)
    local pickerItems = texts:map(function(text)
        return PickerItem.new(TextItem.new(text, TextStyle.PickerView.Text), selectedTexts:contains(text))
    end)
    return PickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem)
end

return PickerView