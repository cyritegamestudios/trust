local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local ConditionsSettingsEditor = setmetatable({}, {__index = FFXIWindow })
ConditionsSettingsEditor.__index = ConditionsSettingsEditor


function ConditionsSettingsEditor.new(trustSettings, conditions, editableConditionClasses)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), ConditionsSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)

    self.trustSettings = trustSettings
    self.conditions = conditions or L{}
    self.editableConditionClasses = editableConditionClasses

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ConditionsSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function ConditionsSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function ConditionsSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1
    for condition in self.conditions:it() do
        local textItem = TextItem.new(condition:tostring(), TextStyle.Default.TextSmall)
        textItem:setShouldTruncateText(true)
        textItem:setEnabled(condition:is_editable())
        items:append(IndexedItem.new(textItem, IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    self:layoutIfNeeded()
end

function ConditionsSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Add' then

    elseif textItem:getText() == 'Remove' then
        self:onRemoveConditionClick()
    elseif textItem:getText() == 'Edit' then

    end
end

function ConditionsSettingsEditor:onRemoveConditionClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local condition = self.conditions[selectedIndexPath.row]
            if not condition:is_editable() then
                addon_system_error("This condition cannot be removed.")
                return
            end
            if condition and self.editableConditionClasses:contains(condition.__class) or condition.__class == NotCondition.__class then
                self.conditions:remove(selectedIndexPath.row)
                self:getDataSource():removeItem(selectedIndexPath)

                if self.trustSettings then
                    self.trustSettings:saveSettings(true)
                end
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've removed this condition!")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't remove this condition!")
            end
        end
    end
end

return ConditionsSettingsEditor