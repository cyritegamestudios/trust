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

function FFXIFastPickerView.new(configItem)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageTextCollectionViewCell.new(item)
        cell:setClipsToBounds(false)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Picker.Default), FFXIFastPickerView)

    self.configItem = configItem
    self.mediaPlayer = defaultMediaPlayer
    self.soundTheme = defaultSoundTheme
    self.textStyle = TextStyle.Picker.Text
    self.maxNumItems = math.min(configItem:getAllValues():length(), 10)
    self.highlightedItem = ValueRelay.new(nil)
    self.selectedItems = ValueRelay.new(L{})
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

function FFXIFastPickerView:setRange(startIndex, endIndex)
    local range = { startIndex = math.max(1, startIndex), endIndex = math.min(self.configItem:getAllValues():length(), endIndex) }
    if self.range and range.endIndex - range.startIndex < self.maxNumItems then
        return
    end
    self.range = range

    local visibleItems = L{}
    for i = startIndex, endIndex do
        if i <= self.configItem:getAllValues():length() then
            local value = self.configItem:getAllValues()[i]
            visibleItems:append(value)
        end
    end

    self.visibleItems = visibleItems

    self:getDataSource():removeAllItems()

    for indexedItem in IndexedItem.fromItems(self.visibleItems, 1):it() do
        local item = self:getItemForValue(indexedItem:getItem())
        self:getDataSource():updateItem(item, indexedItem:getIndexPath())

        if self.selectedItems:getValue():contains(indexedItem:getItem()) then
            self:getDelegate():selectItemAtIndexPath(indexedItem:getIndexPath())
        end
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
        if self.selectedItems:getValue():length() > 0 or self:getAllowsMultipleSelection() then
            self:on_pick_items():trigger(self, self.selectedItems:getValue(), nil) -- FIXME: index paths
        end
    elseif L{ 'Clear All' }:contains(textItem:getText()) then
        self:getDelegate():deselectAllItems()
    end
end

return FFXIFastPickerView