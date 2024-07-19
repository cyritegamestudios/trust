local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Event = require('cylibs/events/Luvent')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
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
            11,
            Color.white,
            Color.lightGrey,
            0,
            0,
            Color.clear,
            true,
            Color.yellow
    ),
}

-- Event called when a list of items are picked.
function PickerView:on_pick_items()
    return self.pick_items
end

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
        local cell
        if item.__type == TextItem.__type then
            cell = TextCollectionViewCell.new(item)
        elseif item.__type == ImageTextItem.__type then
            cell = ImageTextCollectionViewCell.new(item)
        end
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(8, 16, 8, 0)), nil, cursorImageItem), PickerView)

    self.pickerItems = pickerItems
    self.menuArgs = {}

    self:setAllowsMultipleSelection(allowsMultipleSelection)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self:reload()

    self.pick_items = Event.newEvent()

    return self
end

function PickerView:destroy()
    CollectionView.destroy(self)

    self.pick_items:removeAllActions()
end

function PickerView:reload()
    self:getDataSource():removeAllItems()

    local indexedItems = L{}
    local selectedIndexedItems = L{}

    local sections = self.pickerItems

    local sectionIndex = 1
    for section in sections:it() do
        local rowIndex = 1
        for pickerItem in section:it() do
            local indexedItem = IndexedItem.new(pickerItem:getItem(), IndexPath.new(sectionIndex, rowIndex))
            indexedItems:append(indexedItem)
            if pickerItem:isSelected() then
                selectedIndexedItems:append(indexedItem)
            end
            rowIndex = rowIndex + 1
        end
        sectionIndex = sectionIndex + 1
    end

    self:getDataSource():addItems(indexedItems)

    for indexedItem in selectedIndexedItems:it() do
        self:getDelegate():selectItemAtIndexPath(indexedItem:getIndexPath())
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function PickerView:setItems(texts, selectedTexts)
    selectedTexts = selectedTexts or L{}
    self.pickerItems = L{ texts:map(function(text)
        return PickerItem.new(TextItem.new(text, TextStyle.PickerView.Text), selectedTexts:contains(text))
    end) }
    self:reload()
end

function PickerView:getMenuArgs()
    return self.menuArgs
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
    return PickerView.new(L{ pickerItems }, allowsMultipleSelection, cursorImageItem)
end

---
-- Creates a new PickerView with multiple sections of text items.
--
-- @tparam list sections A list of list of text strings.
-- @tparam list selectedTexts A list of selected text strings.
-- @tparam boolean allowsMultipleSelection Indicates if multiple selection is allowed.
-- @tparam ImageItem cursorImageItem (optional) The cursor image item
-- @treturn PickerView The created PickerView.
--
function PickerView.withSections(sections, selectedTexts, allowsMultipleSelection, cursorImageItem)
    local itemsBySection = L{}
    for sectionTexts in sections:it() do
        local pickerItems = sectionTexts:map(function(text)
            return PickerItem.new(TextItem.new(text, TextStyle.PickerView.Text), selectedTexts:contains(text))
        end)
        itemsBySection:append(pickerItems)
    end
    return PickerView.new(itemsBySection, allowsMultipleSelection, cursorImageItem)
end

---
-- Called when the confirm button is pressed.
-- @tparam TextItem textItem Selected item.
-- @tparam IndexPath indexPath Selected index path.
--
function PickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if L{ 'Confirm', 'Save', 'Search' }:contains(textItem:getText()) then
        local selectedItems = L(self:getDelegate():getSelectedIndexPaths():map(function(indexPath)
            return self:getDataSource():itemAtIndexPath(indexPath)
        end)):compact_map()
        if selectedItems:length() > 0 then
            self:on_pick_items():trigger(self, selectedItems)
        end
    end
end

---
-- Adds a new item to the PickerView.
-- @tparam string text Text item to add.
-- @tparam number section Section to add item to.
--
function PickerView:addItem(text, section)
    local newItem = PickerItem.new(TextItem.new(text, TextStyle.PickerView.Text), false)
    self.pickerItems[section]:append(newItem)

    self:reload()
end

return PickerView