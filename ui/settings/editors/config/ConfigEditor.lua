local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIToggleButtonItem = require('ui/themes/ffxi/FFXIToggleButtonItem')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local SliderCollectionViewCell = require('cylibs/ui/collection_view/cells/slider_collection_view_cell')
local SliderItem = require('cylibs/ui/collection_view/items/slider_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local ToggleButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/toggle_button_collection_view_cell')
local ToggleButtonItem = require('cylibs/ui/collection_view/items/toggle_button_item')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local ConfigEditor = setmetatable({}, {__index = FFXIWindow })
ConfigEditor.__index = ConfigEditor


function ConfigEditor.new(trustSettings, configSettings, configItems)
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
        elseif item.__type == FFXIToggleButtonItem.__type then
            local cell = ToggleButtonCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        end
        return nil
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(10, FFXIClassicStyle.Padding.ConfigEditor), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), ConfigEditor)

    self:setAllowsCursorSelection(false)
    self:setAllowsMultipleSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.configSettings = configSettings
    self.configItems = configItems:filter(function(configItem)
        return configSettings[configItem:getKey()] ~= nil
    end)

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ConfigEditor:destroy()
    CollectionView.destroy(self)
end

function ConfigEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local sectionIndex = 1

    for configItem in self.configItems:it() do
        local sectionHeaderItem = SectionHeaderItem.new(
                TextItem.new(configItem:getKey(), TextStyle.Default.SectionHeader),
                ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
                16
        )
        self:getDataSource():setItemForSectionHeader(sectionIndex, sectionHeaderItem)

        local defaultItem
        if configItem.__type == ConfigItem.__type then
            defaultItem = SliderItem.new(
                configItem:getMinValue(),
                configItem:getMaxValue(),
                self.configSettings[configItem:getKey()],
                configItem:getInterval(),
                ImageItem.new(windower.addon_path..'assets/backgrounds/slider_track.png', 166, 16),
                ImageItem.new(windower.addon_path..'assets/backgrounds/slider_fill.png', 166, 16),
                configItem:getTextFormat()
            )
        elseif configItem.__type == BooleanConfigItem.__type then
            defaultItem = FFXIToggleButtonItem.new()
            defaultItem:setEnabled(self.configSettings[configItem:getKey()])
        end

        if defaultItem then
            items:append(IndexedItem.new(defaultItem, IndexPath.new(sectionIndex, 1)))
            sectionIndex = sectionIndex + 1
        end
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function ConfigEditor:onConfirmClick()
    for sectionIndex = 1, self:getDataSource():numberOfSections(), 1 do
        local sectionHeaderItem = self:getDataSource():headerItemForSection(sectionIndex)

        local configItem = self:getDataSource():itemAtIndexPath(IndexPath.new(sectionIndex, 1))
        if configItem.__type == SliderItem.__type then
            self.configSettings[sectionHeaderItem:getTitleItem():getText()] = configItem:getCurrentValue()
        elseif configItem.__type == FFXIToggleButtonItem.__type then
            self.configSettings[sectionHeaderItem:getTitleItem():getText()] = configItem:getEnabled()
        end
    end

    self.trustSettings:saveSettings(true)
    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my settings!")
end

function ConfigEditor:onResetClick()
    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function ConfigEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if L{ 'Confirm', 'Save' }:contains(textItem:getText()) then
        self:onConfirmClick()
    elseif textItem:getText() == 'Reset' then
        self:onResetClick()
    end
end

function ConfigEditor:setHasFocus(focus)
    FFXIWindow.setHasFocus(self, focus)

    if focus then
        self:getDelegate():deselectAllItems()
    end
end

return ConfigEditor