local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local ListView = require('cylibs/ui/list_view/list_view')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local PickerView = require('cylibs/ui/picker/picker_view')
local player_util = require('cylibs/util/player_util')
local spell_util = require('cylibs/util/spell_util')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local TrustSettingsLoader = require('TrustSettings')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local View = require('cylibs/ui/views/view')

local SpellSettingsEditor = setmetatable({}, {__index = CollectionView })
SpellSettingsEditor.__index = SpellSettingsEditor


function SpellSettingsEditor.new(trustSettings, spell)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(20)
        --if indexPath.row ~= 1 then
            cell:setUserInteractionEnabled(true)
        --end
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(15, 10, 0, 0))), SpellSettingsEditor)

    self.trustSettings = trustSettings
    self.spell = spell

    self:setScrollDelta(20)
    self:setScrollEnabled(true)
    self:setAllowsMultipleSelection(true)

    local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId].en end)

    local items = L{}
    local itemsToSelect = L{}
    local rowIndex = 1

    items:append(IndexedItem.new(TextItem.new("Use with job abilities", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    rowIndex = rowIndex + 1
    for jobAbilityName in allJobAbilities:it() do
        local indexPath = IndexPath.new(1, rowIndex)
        items:append(IndexedItem.new(TextItem.new(jobAbilityName, TextStyle.PickerView.Text), indexPath))
        if spell:get_job_abilities():contains(jobAbilityName) then
            itemsToSelect:append(indexPath)
        end
        rowIndex = rowIndex + 1
    end

    rowIndex = 1

    items:append(IndexedItem.new(TextItem.new("Use on specific jobs", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))
    rowIndex = rowIndex + 1
    for jobName in job_util.all_jobs():it() do
        local indexPath = IndexPath.new(2, rowIndex)
        items:append(IndexedItem.new(TextItem.new(jobName, TextStyle.PickerView.Text), indexPath))
        if spell:get_job_names():contains(jobName) then
            itemsToSelect:append(indexPath)
        end
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    for indexPath in itemsToSelect:it() do
        self:getDelegate():selectItemAtIndexPath(indexPath)
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.row == 1 then
            self:getDelegate():selectItemsInSection(indexPath.section)
            self:getDelegate():deselectItemAtIndexPath(indexPath)
        end
        if indexPath.section == 1 then

        elseif indexPath.section == 2 then

        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    return self
end

function SpellSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function SpellSettingsEditor:layoutIfNeeded()
    if not CollectionView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle("Edit settings for "..self.spell:get_spell().en..'.')
end

function SpellSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        self:updateSpell()
    elseif textItem:getText() == 'Clear All' then
        self:getDelegate():deselectAllItems()
    end
end

function SpellSettingsEditor:updateSpell()
    local jobAbilityNames = L{}
    local jobNames = L{}

    local selectedIndexPaths = L(self:getDelegate():getSelectedIndexPaths())
    if selectedIndexPaths:length() > 0 then
        for indexPath in selectedIndexPaths:it() do
            if indexPath.section == 1 then
                local item = self:getDataSource():itemAtIndexPath(indexPath)
                jobAbilityNames:append(item:getText())
            elseif indexPath.section == 2 then
                local item = self:getDataSource():itemAtIndexPath(indexPath)
                jobNames:append(item:getText())
            end
        end
    end

    self.spell:set_job_abilities(jobAbilityNames)
    self.spell:set_job_names(jobNames)

    self.trustSettings:saveSettings(true)

    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll follow these rules for "..self.spell:get_spell().en..'.')
end


return SpellSettingsEditor