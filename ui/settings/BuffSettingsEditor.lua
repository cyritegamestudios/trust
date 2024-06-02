local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local spell_util = require('cylibs/util/spell_util')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local BuffSettingsEditor = setmetatable({}, {__index = FFXIWindow })
BuffSettingsEditor.__index = BuffSettingsEditor


function BuffSettingsEditor.new(trustSettings, buffs, targets)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), BuffSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(20)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.buffs = buffs or L{}
    self.targets = targets
    self.menuArgs = {}

    self.allBuffs = spell_util.get_spells(function(spell)
        return spell.status ~= nil and S{'Self', 'Party'}:intersection(S(spell.targets)):length() > 0
    end)

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function BuffSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function BuffSettingsEditor:onRemoveSpellClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local indexPath = selectedIndexPath
            self.buffs:remove(indexPath.row)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)
        end
    end
end

function BuffSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        self.trustSettings:saveSettings(true)
    elseif textItem:getText() == 'Add' then
        self.menuArgs['spells'] = self.buffs
        self.menuArgs['targets'] = self.targets
    elseif L{ 'Edit', 'Conditions' }:contains(textItem:getText()) then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            self.menuArgs['spell'] = self.buffs[cursorIndexPath.row]
            self.menuArgs['conditions'] = self.buffs[cursorIndexPath.row]:get_conditions()
        end
    elseif textItem:getText() == 'Remove' then
        self:onRemoveSpellClick()
    end
end

function BuffSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function BuffSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function BuffSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1
    for spell in self.buffs:it() do
        items:append(IndexedItem.new(TextItem.new(spell:get_spell().en, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

return BuffSettingsEditor