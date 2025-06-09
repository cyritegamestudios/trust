local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local Mouse = require('cylibs/ui/input/mouse')
local ScrollView = require('cylibs/ui/scroll_view/scroll_view')
local SoundTheme = require('cylibs/sounds/sound_theme')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local ValueRelay = require('cylibs/events/value_relay')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local FFXIFastPickerView = setmetatable({}, {__index = FFXIWindow })
FFXIFastPickerView.__index = FFXIFastPickerView

-- Event called when a list of items are picked.
function FFXIFastPickerView:on_pick_items()
    return self.pick_items
end

function FFXIFastPickerView.new(configItem, viewSize, itemsPerPage)
    viewSize = viewSize or FFXIClassicStyle.WindowSize.Picker.Default

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setClipsToBounds(false)
            cell:setItemSize(16)
            cell:setUserInteractionEnabled(true)
            return cell
        elseif item.__type == ImageTextItem.__type then
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setClipsToBounds(false)
            cell:setItemSize(16)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, viewSize), FFXIFastPickerView)

    if configItem:getInitialValues():length() > 1 then
        self:setAllowsMultipleSelection(true)
    end

    self:setAllowsMultipleSelection(not (configItem:getNumItemsRequired().minNumItems == 1 and configItem:getNumItemsRequired().maxNumItems == 1))
    if self:getAllowsMultipleSelection() then
        self:setAllowsCursorSelection(false)
    end

    self.configItem = configItem
    self.mediaPlayer = defaultMediaPlayer
    self.soundTheme = defaultSoundTheme
    self.textStyle = TextStyle.Picker.Text
    self.maxNumItems = math.min(configItem:getAllValues():length(), itemsPerPage or 10)
    self.highlightedItem = ValueRelay.new(nil)
    self.selectedItems = ValueRelay.new(self.configItem:getInitialValues():copy() or L{})
    self.pick_items = Event.newEvent()

    self:setShouldRequestFocus(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(cursorIndexPath)
        self.highlightedItem = self.visibleItems[cursorIndexPath.row]

        if self.configItem.getItemDescription then
            local description = configItem:getItemDescription(self.highlightedItem)
            if description then
                defaultInfoView:setDescription(description)
                return
            end
        end
    end)

    self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if not self:getAllowsMultipleSelection() then
            self.selectedItems:getValue():clear()
        end

        local item = self.visibleItems[indexPath.row]
        local selectedItems = self.selectedItems:getValue()
        if not selectedItems:contains(item) then
            selectedItems:append(item)
        end
    end)

    self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)
        local item = self.visibleItems[indexPath.row]

        local selectedItems = self.selectedItems:getValue()
        selectedItems:remove(selectedItems:indexOf(item))
    end)

    self:setRange(1, self.maxNumItems + 1)

    return self
end

function FFXIFastPickerView:getItemForValue(value)
    local item = TextItem.new(value, self.textStyle)

    local text, isEnabled = self.configItem:getTextFormat()(value)
    item:setLocalizedText(text)
    item:setShouldTruncateText(i18n.current_locale() ~= i18n.Locale.Japanese)

    if isEnabled ~= nil then
        item:setEnabled(isEnabled)
    end

    local imageItem = self.configItem:getImageItem()(value, 1)
    if imageItem then
        item = ImageTextItem.new(imageItem, item)
    end

    return item
end

function FFXIFastPickerView:setRange(startIndex, endIndex, shouldReload)
    local range = { startIndex = math.max(1, startIndex), endIndex = math.min(self.configItem:getAllValues():length(), endIndex) }
    if self.range and not shouldReload and (range.endIndex - range.startIndex < self.maxNumItems
            or range.startIndex == self.range.startIndex and range.endIndex == self.range.endIndex) then
        return
    end
    self.range = range

    local visibleItems = L{}

    local allValues = self.configItem:getAllValues()
    for i = startIndex, endIndex do
        if i <= allValues:length() then
            local value = allValues[i]
            visibleItems:append(value)
        end
    end

    self.visibleItems = visibleItems

    self:getDataSource():removeAllItems()

    local itemsToUpdate = L{}
    local selectedIndexPaths = L{}
    for indexedItem in IndexedItem.fromItems(self.visibleItems, 1):it() do
        local item = self:getItemForValue(indexedItem:getItem())
        itemsToUpdate:append(IndexedItem.new(item, indexedItem:getIndexPath()))
        if self.selectedItems:getValue():contains(indexedItem:getItem()) then
            selectedIndexPaths:append(indexedItem:getIndexPath())
        end
    end

    self:getDataSource():updateItems(itemsToUpdate)

    for selectedIndexPath in selectedIndexPaths:it() do
        self:getDelegate():selectItemAtIndexPath(selectedIndexPath)
    end

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    self:layoutIfNeeded()
end

function FFXIFastPickerView:layoutIfNeeded()
    if not FFXIWindow.layoutIfNeeded(self) or self.contentView == nil then
        return false
    end

    if self.verticalScrollBar then
        self.verticalScrollBar:setVisible(self.configItem:getAllValues():length() > self.maxNumItems)
    end

    for scrollBar in self.scrollBars:it() do
        scrollBar:layoutIfNeeded()
    end

    if self.searchBarView then
        self.searchBarView:setPosition(self:getSize().width + 4, 0)
        self.searchBarView:layoutIfNeeded()
    end

    return true
end

function FFXIFastPickerView:onKeyboardEvent(key, pressed, flags, blocked)
    local blocked = blocked or ScrollView.onKeyboardEvent(self, key, pressed, flags, blocked)
    if not self:isVisible() or blocked or self.destroyed then
        return blocked
    end
    if pressed then
        local keyName = Keyboard.input():getKey(key, flags)
        self:playSoundsForKey(keyName)

        local currentIndexPath = self:getDelegate():getCursorIndexPath()
        if currentIndexPath then
            if key == 208 then
                self.isScrolling = true
                local nextIndexPath = self:getDataSource():getNextIndexPath(currentIndexPath, false)
                if nextIndexPath == currentIndexPath then
                    self:setRange(self.range.startIndex + 1, self.range.endIndex + 1)
                end
                self:getDelegate():setCursorIndexPath(nextIndexPath)
                return true
            elseif key == 200 then
                self.isScrolling = true
                local nextIndexPath = self:getDataSource():getPreviousIndexPath(currentIndexPath, false)
                if nextIndexPath == currentIndexPath then
                    self:setRange(self.range.startIndex - 1, self.range.endIndex - 1)
                end
                self:getDelegate():setCursorIndexPath(nextIndexPath)
                return true
            elseif key == 28 then
                if self.mediaPlayer and self.soundTheme then
                    if self:getDelegate():shouldSelectItemAtIndexPath(self:getDelegate():getCursorIndexPath()) then
                        self.mediaPlayer:playSound(self.soundTheme:getSoundForAction(SoundTheme.UI.Menu.Enter))
                    end
                end
                self:getDelegate():selectItemAtIndexPath(self:getDelegate():getCursorIndexPath())
            else
                self.isScrolling = false
            end
        end
    else
        self.isScrolling = false
    end
    return L{ 200, 208 }:contains(key)
end

function FFXIFastPickerView:onMouseEvent(type, x, y, delta)
    if not self:isVisible() then
        return false
    end
    if CollectionView.onMouseEvent(self, type, x, y, delta) then
        return true
    end
    if type == Mouse.Event.Wheel then
        if delta < 0 then
            self:setRange(self.range.startIndex + 1, self.range.endIndex + 1)
        else
            self:setRange(self.range.startIndex - 1, self.range.endIndex - 1)
        end
        return true
    end
    return false
end

---
-- Called when the confirm button is pressed.
-- @tparam TextItem textItem Selected item.
-- @tparam IndexPath indexPath Selected index path.
--
function FFXIFastPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if L{ 'Confirm', 'Save', 'Search', 'Select' }:contains(textItem:getText()) then
        local numItemsSelected = self.selectedItems:getValue():length()

        local minNumItems = self.configItem:getNumItemsRequired().minNumItems
        local maxNumItems = self.configItem:getNumItemsRequired().maxNumItems

        local validate = function(numItemsSelected)
            local success = true
            local message
            if minNumItems == maxNumItems and numItemsSelected ~= minNumItems then
                success = false
                message = string.format("You must select %d item(s).", minNumItems)
            elseif numItemsSelected < minNumItems or numItemsSelected > maxNumItems then
                success = false
                message = string.format("You must select between %d and %d item(s).", minNumItems, maxNumItems)
            end
            return success, message
        end

        local is_valid, message = validate(numItemsSelected)
        if is_valid then
            self:on_pick_items():trigger(self, self.selectedItems:getValue(), nil)
        else
            addon_system_error(message or "Invalid selection.")
        end
    elseif L{ 'Clear All' }:contains(textItem:getText()) then
        self.selectedItems:getValue():clear()
        self:getDelegate():deselectAllItems()
    elseif L{ 'Filter' }:contains(textItem:getText()) then
        self:setSearchEnabled(true)
    end
end

function FFXIFastPickerView:setFilter(filter)
    self:setRange(1, self.maxNumItems + 1, true)

    local selectedValues = L(self:getDelegate():getSelectedIndexPaths():map(function(indexPath)
        return self:getDataSource():itemAtIndexPath(indexPath):getText()
    end)):compact_map()

    if self.configItem.setFilter then
        self.configItem:setFilter(function(value)
            return selectedValues:contains(value) or filter(value)
        end)
        self:setRange(1, self.maxNumItems + 1, true)
    end
end

function FFXIFastPickerView:setSearchEnabled(searchEnabled)
    if searchEnabled then
        if self.searchBarView == nil then
            local SearchBarView = require('ui/settings/pickers/SearchBarView')
            self.searchBarView = SearchBarView.new()
            self:addSubview(self.searchBarView)

            self.searchBarView:onSearchQueryChanged():addAction(function(_, query, _)
                self:setFilter(function(value)
                    return self.configItem:getTextFormat()(value):contains(query)
                end)
            end)

            self.searchBarView:setNeedsLayout()
            self.searchBarView:layoutIfNeeded()

            self:setNeedsLayout()
            self:layoutIfNeeded()
        end

        self:requestFocus()

        self.searchBarView:setVisible(true)
        self.searchBarView:requestFocus()
    end
end

function FFXIFastPickerView:setHasFocus(hasFocus)
    FFXIWindow.setHasFocus(self, hasFocus)

    if self:hasFocus() then
        if self.searchBarView then
            self.searchBarView:setVisible(false)
        end
    end
end

return FFXIFastPickerView