local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local player_util = require('cylibs/util/player_util')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local SpellSettingsEditor = setmetatable({}, {__index = FFXIWindow })
SpellSettingsEditor.__index = SpellSettingsEditor


function SpellSettingsEditor.new(trustSettings, spell, hideJobs)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, FFXIClassicStyle.Padding.ConfigEditor, 6), nil, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor), SpellSettingsEditor)

    self.trustSettings = trustSettings
    self.spell = spell
    self.hideJobs = hideJobs
    self.menuArgs = {}

    self:setScrollDelta(16)
    self:setScrollEnabled(true)
    self:setAllowsMultipleSelection(true)

    local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId].en end)

    local items = L{}
    local itemsToSelect = L{}
    local rowIndex = 1

    local jobAbilitiesSectionHeaderItem = SectionHeaderItem.new(
        TextItem.new("Use with job abilities", TextStyle.Default.SectionHeader),
        ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
        16
    )
    self:getDataSource():setItemForSectionHeader(1, jobAbilitiesSectionHeaderItem)

    for jobAbilityName in allJobAbilities:it() do
        local indexPath = IndexPath.new(1, rowIndex)
        items:append(IndexedItem.new(TextItem.new(jobAbilityName, TextStyle.Default.TextSmall), indexPath))
        if spell:get_job_abilities():contains(jobAbilityName) then
            itemsToSelect:append(indexPath)
        end
        rowIndex = rowIndex + 1
    end

    rowIndex = 1

    if not self.hideJobs then
        local jobsSectionHeaderItem = SectionHeaderItem.new(
                TextItem.new("Use on specific jobs", TextStyle.Default.SectionHeader),
                ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
                16
        )
        self:getDataSource():setItemForSectionHeader(2, jobsSectionHeaderItem)
        for jobName in job_util.all_jobs():it() do
            local indexPath = IndexPath.new(2, rowIndex)
            items:append(IndexedItem.new(TextItem.new(jobName, TextStyle.Default.TextSmall), indexPath))
            if spell:get_job_names():contains(jobName) then
                itemsToSelect:append(indexPath)
            end
            rowIndex = rowIndex + 1
        end
    end

    self:getDataSource():addItems(items)

    for indexPath in itemsToSelect:it() do
        self:getDelegate():selectItemAtIndexPath(indexPath)
    end

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.row == 1 then
            --self:getDelegate():selectItemsInSection(indexPath.section)
            --self:getDelegate():deselectItemAtIndexPath(indexPath)
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
    elseif textItem:getText() == 'Conditions' then
        self.menuArgs['conditions'] = self.spell:get_conditions()
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

function SpellSettingsEditor:getMenuArgs()
    return self.menuArgs
end

return SpellSettingsEditor