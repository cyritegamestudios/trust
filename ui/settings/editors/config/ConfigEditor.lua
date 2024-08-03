local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIToggleButtonItem = require('ui/themes/ffxi/FFXIToggleButtonItem')
local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerCollectionViewCell = require('cylibs/ui/collection_view/cells/picker_collection_view_cell')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local PickerItem = require('cylibs/ui/collection_view/items/picker_item')
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

function ConfigEditor:onConfigChanged()
    return self.configChanged
end


function ConfigEditor.new(trustSettings, configSettings, configItems, infoView)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == SliderItem.__type then
            local cell = SliderCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == FFXIToggleButtonItem.__type then
            local cell = ToggleButtonCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == PickerItem.__type then
            local cell = PickerCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        end
        return nil
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.ConfigEditor, 10), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), ConfigEditor)

    self:setAllowsCursorSelection(false)
    self:setAllowsMultipleSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.configSettings = configSettings
    self.configChanged = Event.newEvent()

    self:setConfigItems(configItems)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if infoView then
            local cell = self:getDataSource():cellForItemAtIndexPath(indexPath)
            if cell and cell.__type == PickerCollectionViewCell.__type then
                infoView:setDescription("Hold shift and press the left and right arrow keys to cycle faster.")
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)
        if infoView then
            infoView:setDescription("Edit the selected condition.")
        end
        local configItem = self.configItems[indexPath.section]
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if (item.getCurrentValue and configItem.getInitialValue) and item:getCurrentValue() ~= configItem:getInitialValue() then
            for dependency in configItem:getDependencies():it() do
                if dependency.onReload then
                    local allValues = dependency.onReload(configItem:getKey(), item:getCurrentValue())
                    dependency:setAllValues(allValues)

                    self:reloadConfigItem(dependency)
                end
            end
        end
    end), self:getDelegate():didDeselectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ConfigEditor:destroy()
    FFXIWindow.destroy(self)
end

function ConfigEditor:setConfigItems(configItems)
    self.configItems = configItems:filter(function(configItem)
        return self.configSettings[configItem:getKey()] ~= nil
    end)
    self.numSections = self.configItems:length()
    self:reloadSettings()
end

function ConfigEditor:reloadConfigItem(configItem)
    local sectionIndex = self.configItems:indexOf(configItem)

    self:getDataSource():removeItemsInSection(sectionIndex)

    local items = L{}

    local defaultItems = L{}
    if configItem.__type == GroupConfigItem.__type then
        for childConfigItem in configItem:getConfigItems():it() do
            defaultItems:append(self:getCellItemForConfigItem(childConfigItem))
        end
    else
        defaultItems:append(self:getCellItemForConfigItem(configItem))
    end

    if defaultItems:length() > 0 then
        local rowIndex = 1
        for defaultItem in defaultItems:it() do
            items:append(IndexedItem.new(defaultItem, IndexPath.new(sectionIndex, rowIndex)))
            rowIndex = rowIndex + 1
        end
        sectionIndex = sectionIndex + 1
    end

    self:getDataSource():addItems(items)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function ConfigEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local sectionIndex = 1

    for configItem in self.configItems:it() do
        local sectionHeaderItem = SectionHeaderItem.new(
                TextItem.new(configItem:getDescription(), TextStyle.Default.SectionHeader),
                ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
                16
        )
        self:getDataSource():setItemForSectionHeader(sectionIndex, sectionHeaderItem)

        local defaultItems = L{}
        if configItem.__type == GroupConfigItem.__type then
            for childConfigItem in configItem:getConfigItems():it() do
                defaultItems:append(self:getCellItemForConfigItem(childConfigItem))
            end
        else
            defaultItems:append(self:getCellItemForConfigItem(configItem))
        end

        if defaultItems:length() > 0 then
            local rowIndex = 1
            for defaultItem in defaultItems:it() do
                items:append(IndexedItem.new(defaultItem, IndexPath.new(sectionIndex, rowIndex)))
                rowIndex = rowIndex + 1
            end
            sectionIndex = sectionIndex + 1
        end
    end

    self.numSections = sectionIndex - 1

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function ConfigEditor:getCellItemForConfigItem(configItem)
    if configItem.__type == ConfigItem.__type then
        return SliderItem.new(
            configItem:getMinValue(),
            configItem:getMaxValue(),
            self.configSettings[configItem:getKey()],
            configItem:getInterval(),
            ImageItem.new(windower.addon_path..'assets/backgrounds/slider_track.png', 166, 16),
            ImageItem.new(windower.addon_path..'assets/backgrounds/slider_fill.png', 166, 16),
            configItem:getTextFormat()
        )
    elseif configItem.__type == BooleanConfigItem.__type then
        local defaultItem = FFXIToggleButtonItem.new()
        defaultItem:setEnabled(self.configSettings[configItem:getKey()])
        return defaultItem
    elseif configItem.__type == PickerConfigItem.__type then
        return PickerItem.new(configItem:getInitialValue(), configItem:getAllValues(), configItem:getTextFormat())
    end
    return nil
end

function ConfigEditor:onConfirmClick(skipSave)
    local originalSettings
    if self.configSettings.copy then
        originalSettings = self.configSettings:copy()
    else
        originalSettings = T(self.configSettings):copy(true)
    end
    for sectionIndex = 1, self:getDataSource():numberOfSections(), 1 do
        local configItem = self.configItems[sectionIndex]
        if configItem then
            local configKey = configItem:getKey()
            if configItem.__type == GroupConfigItem.__type then
                local configValues = L{}
                for rowIndex = 1, configItem:getConfigItems():length() do
                    local cellConfigItem = self:getDataSource():itemAtIndexPath(IndexPath.new(sectionIndex, rowIndex))
                    if cellConfigItem.__type == SliderItem.__type then
                        configValues:append(cellConfigItem:getCurrentValue())
                    elseif cellConfigItem.__type == FFXIToggleButtonItem.__type then
                        configValues:append(cellConfigItem:getEnabled())
                    elseif cellConfigItem.__type == PickerItem.__type then
                        configValues:append(cellConfigItem:getCurrentValue())
                    end
                end
                configValues = configValues:filter(function(value) return value ~= 'None' end)
                self.configSettings[configKey] = configValues
            else
                local cellConfigItem = self:getDataSource():itemAtIndexPath(IndexPath.new(sectionIndex, 1))

                if cellConfigItem.__type == SliderItem.__type then
                    self.configSettings[configKey] = cellConfigItem:getCurrentValue()
                elseif cellConfigItem.__type == FFXIToggleButtonItem.__type then
                    self.configSettings[configKey] = cellConfigItem:getEnabled()
                elseif cellConfigItem.__type == PickerItem.__type then
                    self.configSettings[configKey] = cellConfigItem:getCurrentValue()
                end
            end
        end
    end

    self:onConfigChanged():trigger(self.configSettings, originalSettings)

    if self.trustSettings and not skipSave then
        self.trustSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my settings!")
    end
end

function ConfigEditor:onResetClick()
    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function ConfigEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if L{ 'Confirm', 'Save', 'Search' }:contains(textItem:getText()) then
        self:onConfirmClick()
    elseif textItem:getText() == 'Reset' then
        self:onResetClick()
    end
end

function ConfigEditor:setHasFocus(focus)
    FFXIWindow.setHasFocus(self, focus)

    if focus then
        local sections = S{}
        for i = 1, self.numSections do
            sections:add(i)
        end
        self:getDelegate():deselectItemsInSections(sections)
    end
end

return ConfigEditor