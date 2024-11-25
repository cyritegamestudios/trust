local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Event = require('cylibs/events/Luvent')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Padding = require('cylibs/ui/style/padding')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local PickerItem = require('cylibs/ui/picker/picker_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local PickerView = setmetatable({}, {__index = CollectionView })
PickerView.__index = PickerView
PickerView.__type = "PickerView"

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
-- @treturn PickerView The created PickerView.
--
function PickerView.new(configItems, allowsMultipleSelection, mediaPlayer, soundTheme)
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

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(8, 16, 8, 0)), nil, nil, mediaPlayer, soundTheme), PickerView)

    self.configItems = configItems
    self.menuArgs = {}

    self:setAllowsMultipleSelection(allowsMultipleSelection)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self:getDisposeBag():add(self:getDataSource():onItemsWillChange():addAction(function(_, removedIndexPaths, _)
        for _, indexPath in pairs(removedIndexPaths) do
            -- this causes items to be removed from the data source during reload
            --self.pickerItems[indexPath.section]:remove(indexPath.row)
        end
    end), self:getDataSource():onItemsWillChange())

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
    local selectedIndexPaths = L{}

    local configItems = self.configItems

    local sectionIndex = 1
    for configItem in configItems:it() do
        local rowIndex = 1
        local itemsInSection = IndexedItem.fromItems(configItem:getAllValues():map(function(value)
            local item = TextItem.new(value, TextStyle.Picker.Text)
            item:setLocalizedText(configItem:getTextFormat()(value))

            local imageItem = configItem:getImageItem()(value, sectionIndex)
            if imageItem then
                item = ImageTextItem.new(imageItem, item)
            end
            local isSelected = S(configItem:getInitialValues()):contains(value)
            if isSelected then
                selectedIndexPaths:append(IndexPath.new(sectionIndex, rowIndex))
            end
            rowIndex = rowIndex + 1
            return item
        end), sectionIndex)

        indexedItems = indexedItems + itemsInSection

        --[[for configItem in section:it() do
            local indexedItem = IndexedItem.new(pickerItem:getItem(), IndexPath.new(sectionIndex, rowIndex))
            indexedItems:append(indexedItem)
            if pickerItem:isSelected() then
                selectedIndexedItems:append(indexedItem)
            end
            rowIndex = rowIndex + 1
        end]]
        sectionIndex = sectionIndex + 1
    end

    self:getDataSource():addItems(indexedItems)

    for indexPath in selectedIndexPaths:it() do
        self:getDelegate():selectItemAtIndexPath(indexPath)
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function PickerView:setItems(texts, selectedTexts, shouldTruncateText)
    error("FIX ME")
    selectedTexts = selectedTexts or L{}
    self.pickerItems = L{ texts:map(function(text)
        local textItem = TextItem.new(text, TextStyle.Picker.Text)
        textItem:setShouldTruncateText(shouldTruncateText)
        return PickerItem.new(textItem, selectedTexts:contains(text))
    end) }
    self:reload()
end

function PickerView:getMenuArgs()
    return self.menuArgs
end

function PickerView:valueAtIndexPath(indexPath)
    local configItem = self.configItems[indexPath.section]
    return configItem:getAllValues()[indexPath.row]
end

---
-- Creates a new PickerView with text items.
--
-- @tparam list texts A list of text strings.
-- @tparam list selectedTexts A list of selected text strings.
-- @tparam boolean allowsMultipleSelection Indicates if multiple selection is allowed.
-- @treturn PickerView The created PickerView.
--
function PickerView.withItems(texts, selectedTexts, allowsMultipleSelection)
    local pickerItems = texts:map(function(text)
        return PickerItem.new(TextItem.new(text, TextStyle.Picker.Text), selectedTexts:contains(text))
    end)
    return PickerView.new(L{ pickerItems }, allowsMultipleSelection)
end

---
-- Creates a new PickerView with multiple sections of text items.
--
-- @tparam list sections A list of list of text strings.
-- @tparam list selectedTexts A list of selected text strings.
-- @tparam boolean allowsMultipleSelection Indicates if multiple selection is allowed.
-- @treturn PickerView The created PickerView.
--
function PickerView.withSections(sections, selectedTexts, allowsMultipleSelection)
    local itemsBySection = L{}
    for sectionTexts in sections:it() do
        local pickerItems = sectionTexts:map(function(text)
            return PickerItem.new(TextItem.new(text, TextStyle.Picker.Text), selectedTexts:contains(text))
        end)
        itemsBySection:append(pickerItems)
    end
    return PickerView.new(itemsBySection, allowsMultipleSelection)
end

---
-- Called when the confirm button is pressed.
-- @tparam TextItem textItem Selected item.
-- @tparam IndexPath indexPath Selected index path.
--
function PickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if L{ 'Confirm', 'Save', 'Search', 'Select' }:contains(textItem:getText()) then
        local selectedItems = L(self:getDelegate():getSelectedIndexPaths():map(function(indexPath)
            return self:valueAtIndexPath(indexPath)-- self:getDataSource():itemAtIndexPath(indexPath)
        end)):compact_map()
        if selectedItems:length() > 0 or self:getAllowsMultipleSelection() then
            self:on_pick_items():trigger(self, selectedItems, L(self:getDelegate():getSelectedIndexPaths()))
        end
    elseif L{ 'Clear All' }:contains(textItem:getText()) then
        self:getDelegate():deselectAllItems()
    end
end

---
-- Adds a new item to the PickerView.
-- @tparam string text Text item to add.
-- @tparam number section Section to add item to.
--
function PickerView:addItem(text, section)
    local newItem = PickerItem.new(TextItem.new(text, TextStyle.Picker.Text), false)
    self.pickerItems[section]:append(newItem)

    self:reload()
end

return PickerView