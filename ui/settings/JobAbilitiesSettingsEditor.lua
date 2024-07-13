local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ListView = require('cylibs/ui/list_view/list_view')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local PickerView = require('cylibs/ui/picker/picker_view')
local player_util = require('cylibs/util/player_util')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')
local spell_util = require('cylibs/util/spell_util')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local TrustSettingsLoader = require('TrustSettings')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local JobAbilitiesSettingsEditor = setmetatable({}, {__index = FFXIWindow })
JobAbilitiesSettingsEditor.__index = JobAbilitiesSettingsEditor


function JobAbilitiesSettingsEditor.new(trustSettings, settingsMode, settingsPrefix)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = ImageTextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), JobAbilitiesSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.settingsMode = settingsMode
    self.settingsPrefix = settingsPrefix
    self.menuArgs = {}

    self.allBuffs = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
        return jobAbility.status ~= nil and S{'Self'}:intersection(S(jobAbility.targets)):length() > 0
    end)

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function JobAbilitiesSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function JobAbilitiesSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit job abilities on the player.")
end

function JobAbilitiesSettingsEditor:onRemoveJobAbilityClick()
    local selectedIndexPath = self:getDelegate():getCursorIndexPath()
    if selectedIndexPath then
        local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
        if item then
            local indexPath = selectedIndexPath
            self.jobAbilities:remove(indexPath.row)
            self:getDataSource():removeItem(indexPath)
            self.trustSettings:saveSettings(true)
        end
    end
end

function JobAbilitiesSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Remove' then
        self:onRemoveJobAbilityClick()
    elseif textItem:getText() == 'Conditions' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            self.menuArgs['conditions'] = self.jobAbilities[cursorIndexPath.row]:get_conditions()
        end
    end
end

function JobAbilitiesSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function JobAbilitiesSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function JobAbilitiesSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local items = L{}

    if self.settingsPrefix then
        self.jobAbilities = T(self.trustSettings:getSettings())[self.settingsMode.value][self.settingsPrefix].JobAbilities
    else
        self.jobAbilities = T(self.trustSettings:getSettings())[self.settingsMode.value].JobAbilities
    end

    local rowIndex = 1

    for jobAbility in self.jobAbilities:it() do
        local imageItem = AssetManager.imageItemForJobAbility(jobAbility:get_job_ability_name())
        items:append(IndexedItem.new(ImageTextItem.new(imageItem, TextItem.new(jobAbility:get_job_ability_name(), TextStyle.Default.PickerItem)), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self.jobAbilities:length() > 0 then
        self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
    end
end

return JobAbilitiesSettingsEditor