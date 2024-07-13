local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local JobAbility = require('cylibs/battle/abilities/job_ability')
local Spell = require('cylibs/battle/spell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local PullActionSettingsEditor = setmetatable({}, {__index = FFXIWindow })
PullActionSettingsEditor.__index = PullActionSettingsEditor


function PullActionSettingsEditor.new(trustSettings, abilities)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        local cell = ImageTextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), PullActionSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.abilities = abilities
    self.menuArgs = {}

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PullActionSettingsEditor:onRemoveAbilityClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local indexPath = selectedIndexPath
            self.abilities:remove(indexPath.row)
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll no longer use "..localization_util.translate(item:getText()).." to pull!")
        end
    end
end

function PullActionSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        self.trustSettings:saveSettings(true)
    elseif textItem:getText() == 'Add' then
        --self.menuArgs['spells'] = self.buffs
        --self.menuArgs['targets'] = self.targets
    elseif L{ 'Edit', 'Conditions' }:contains(textItem:getText()) then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            self.menuArgs['conditions'] = self.abilities[cursorIndexPath.row]:get_conditions()
        end
    elseif textItem:getText() == 'Remove' then
        self:onRemoveAbilityClick()
    end
end

function PullActionSettingsEditor:imageItemForAbility(ability)
    if ability.__class == Spell.__class then
        return AssetManager.imageItemForSpell(ability:get_name())
    elseif ability.__class == JobAbility.__class then
        return AssetManager.imageItemForJobAbility(ability:get_name())
    else
        return AssetManager.imageItemForJobAbility(ability:get_name())
    end
end

function PullActionSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    local rowIndex = 1
    for ability in self.abilities:it() do
        local imageItem = self:imageItemForAbility(ability)
        items:append(IndexedItem.new(ImageTextItem.new(imageItem, TextItem.new(ability:get_name(), TextStyle.Default.PickerItem)), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function PullActionSettingsEditor:getMenuArgs()
    return self.menuArgs
end

return PullActionSettingsEditor