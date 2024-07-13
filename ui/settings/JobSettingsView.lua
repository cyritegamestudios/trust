local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local JobSettingsView = setmetatable({}, {__index = FFXIWindow })
JobSettingsView.__index = JobSettingsView


function JobSettingsView.new(jobSettingsMode, jobSettings)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), JobSettingsView)

    self.jobSettings = jobSettings

    self:setAllowsMultipleSelection(false)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    local itemsToAdd = L{}
    local itemsToSelect = L{}

    local rowIndex = 1
    for _, v in ipairs(jobSettingsMode) do
        local item = TextItem.new(tostring(v), TextStyle.Default.TextSmall)
        local indexPath = IndexPath.new(1, rowIndex)
        itemsToAdd:append(IndexedItem.new(item, indexPath))
        if item:getText() == jobSettingsMode.value then
            itemsToSelect:append(indexPath)
        end
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(itemsToAdd)

    for indexPath in itemsToSelect:it() do
        self:getDelegate():selectItemAtIndexPath(indexPath)
    end

    local updateSelectedItems = function(section, selectedItem)
        for row = 1, self:getDataSource():numberOfItemsInSection(section) do
            local indexPath = IndexPath.new(1, row)
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            if item and item:getText() ~= selectedItem:getText() then
                --self:getDelegate():deselectItemAtIndexPath(indexPath)
            end
        end
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            updateSelectedItems(1, item)
            handle_set('MainTrustSettingsMode', item:getText())
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function JobSettingsView:destroy()
    CollectionView.destroy(self)
end

function JobSettingsView:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Load saved job settings.")
end

function JobSettingsView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Delete' then
        local selectedIndexPath = L(self:getDelegate():getSelectedIndexPaths())[1]
        if selectedIndexPath then
            local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item:getText() ~= 'Default' then
                self.jobSettings:deleteSettings(item:getText())
                self:getDataSource():removeItem(selectedIndexPath)
                addon_message(260, '('..windower.ffxi.get_player().name..') '..item:getText().."? What "..item:getText().."?")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..") I can't forget Default!")
            end
        end
    end
end

return JobSettingsView