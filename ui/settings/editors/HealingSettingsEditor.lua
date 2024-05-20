local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SliderCollectionViewCell = require('cylibs/ui/collection_view/cells/slider_collection_view_cell')
local SliderItem = require('cylibs/ui/collection_view/items/slider_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local HealingSettingsEditor = setmetatable({}, {__index = FFXIWindow })
HealingSettingsEditor.__index = HealingSettingsEditor


function HealingSettingsEditor.new(trustSettings, cureSettings)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == SliderItem.__type then
            local cell = SliderCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(false)
            cell:setIsSelectable(false)
            cell:setItemSize(16)
            return cell
        end
        return nil
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(10, Padding.new(15, 10, 0, 0))), HealingSettingsEditor)

    self:setAllowsCursorSelection(false)
    self:setScrollDelta(16)

    self.trustSettings = trustSettings
    self.cureSettings = cureSettings

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function HealingSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function HealingSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1

    local entries = L(T(self.cureSettings.Thresholds):keyset())

    local configForEntry = function(entry)
        if L{'Default', 'Emergency'}:contains(entry) then
            return { minValue = 0, maxValue = 100, interval = 1, textFormat = function(value) return value.." %" end }
        else
            return { minValue = 0, maxValue = 2000, interval = 100, textFormat = function(value) return tostring(value) end }
        end
    end

    for entry in entries:it() do
        items:append(IndexedItem.new(TextItem.new(entry, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))

        local config = configForEntry(entry)

        local defaultItem = SliderItem.new(
                config.minValue,
                config.maxValue,
                self.cureSettings.Thresholds[entry],
                config.interval,
                ImageItem.new(windower.addon_path..'assets/backgrounds/slider_track.png', 166, 16),
                ImageItem.new(windower.addon_path..'assets/backgrounds/slider_fill.png', 166, 16),
                config.textFormat
        )
        items:append(IndexedItem.new(defaultItem, IndexPath.new(1, rowIndex + 1)))

        rowIndex = rowIndex + 2
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function HealingSettingsEditor:onConfirmClick()
    for rowIndex = 1, self:getDataSource():numberOfItemsInSection(1), 2 do
        local entryItem = self:getDataSource():itemAtIndexPath(IndexPath.new(1, rowIndex))
        local sliderItem = self:getDataSource():itemAtIndexPath(IndexPath.new(1, rowIndex + 1))

        self.cureSettings.Thresholds[entryItem:getText()] = sliderItem:getCurrentValue()
    end

    self.trustSettings:saveSettings(true)
    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my cure thresholds!")
end

function HealingSettingsEditor:onResetClick()
    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function HealingSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Confirm' then
        self:onConfirmClick()
    elseif textItem:getText() == 'Reset' then
        self:onResetClick()
    end
end

function HealingSettingsEditor:setHasFocus(focus)
    FFXIWindow.setHasFocus(self, focus)

    if focus then
        self:getDelegate():deselectAllItems()
    end
end

return HealingSettingsEditor