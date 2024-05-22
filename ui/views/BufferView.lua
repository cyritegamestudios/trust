local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local BufferView = setmetatable({}, {__index = FFXIWindow })
BufferView.__index = BufferView
BufferView.__type = 'BufferView'

TextStyle.BufferView = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            10,
            Color.white,
            Color.yellow,
            2,
            0,
            Color.clear,
            false
    ),
}

function BufferView.new(buffer)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setIsSelectable(false)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0), 6)), BufferView)

    self:setScrollDelta(20)
    self:setShouldRequestFocus(false)
    self:setScrollEnabled(false)

    local itemsToAdd = L{}
    local itemsToHighlight = L{}

    local sectionNum = 1

    local jobAbilityNames = buffer:get_job_abilities():map(function(job_ability) return job_ability:get_job_ability_name() end)
    if jobAbilityNames:length() > 0 then
        local jobAbilitySectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Job abilities", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
        )
        self:getDataSource():setItemForSectionHeader(sectionNum, jobAbilitySectionHeaderItem)
        local currentRow = 1
        for job_ability_name in jobAbilityNames:it() do
            local item = TextItem.new('• '..job_ability_name, TextStyle.Default.TextSmall)
            local indexPath = IndexPath.new(sectionNum, currentRow)
            itemsToAdd:append(IndexedItem.new(item, indexPath))
            if buffer:is_job_ability_buff_active(job_ability_name) then
                itemsToHighlight:append(IndexedItem.new(item, indexPath))
            end
            currentRow = currentRow + 1
        end
        sectionNum = sectionNum + 1
    end

    local selfSpells = buffer:get_self_spells()
    if selfSpells:length() > 0 then
        local selfSpellsSectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Buffs on self", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
        )
        self:getDataSource():setItemForSectionHeader(sectionNum, selfSpellsSectionHeaderItem)
        local currentRow = 1
        for spell in selfSpells:it() do
            local item = TextItem.new('• '..spell:description(), TextStyle.BufferView.Text)
            local indexPath = IndexPath.new(sectionNum, currentRow)
            itemsToAdd:append(IndexedItem.new(item, indexPath))
            if buffer:is_self_buff_active(spell) then
                itemsToHighlight:append(IndexedItem.new(item, indexPath))
            end
            currentRow = currentRow + 1
        end
        sectionNum = sectionNum + 1
    end

    local partySpells = buffer:get_party_spells()
    if partySpells:length() > 0 then
        local partySpellsSectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Buffs on party", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
        )
        self:getDataSource():setItemForSectionHeader(sectionNum, partySpellsSectionHeaderItem)
        local currentRow = 1
        for spell in partySpells:it() do
            local item = TextItem.new('• '..spell:description(), TextStyle.BufferView.Text)
            local indexPath = IndexPath.new(sectionNum, currentRow)
            itemsToAdd:append(IndexedItem.new(item, indexPath))
            currentRow = currentRow + 1
        end
    end

    dataSource:addItems(itemsToAdd)

    for indexedItem in itemsToHighlight:it() do
        self:getDelegate():highlightItemAtIndexPath(indexedItem:getIndexPath())
    end

    self:layoutIfNeeded()

    return self
end

function BufferView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("View current buffs on the player and party.")
end

return BufferView