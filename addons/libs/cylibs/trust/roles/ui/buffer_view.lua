local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local BufferView = setmetatable({}, {__index = CollectionView })
BufferView.__index = BufferView

TextStyle.BufferView = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.green,
            2,
            0,
            0,
            false
    ),
}

function BufferView.new(buffer)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), BufferView)

    local jobAbilityNames = buffer:get_job_ability_names()
    if jobAbilityNames:length() > 0 then
        dataSource:addItem(TextItem.new("Job Abilities", TextStyle.BufferView.Text), IndexPath.new(1, 1))
        local currentRow = 2
        for job_ability_name in jobAbilityNames:it() do
            local item = TextItem.new('• '..job_ability_name, TextStyle.BufferView.Text)
            local indexPath = IndexPath.new(1, currentRow)
            dataSource:addItem(item, indexPath)
            if buffer:is_job_ability_buff_active(job_ability_name) then
                self:getDelegate():highlightItemAtIndexPath(item, indexPath)
            end
            currentRow = currentRow + 1
        end
        dataSource:addItem(TextItem.new("", TextStyle.BufferView.Text), IndexPath.new(1, currentRow))
    end

    local selfSpells = buffer:get_self_spells()
    if selfSpells:length() > 0 then
        dataSource:addItem(TextItem.new("Self Spells", TextStyle.BufferView.Text), IndexPath.new(2, 1))
        local currentRow = 2
        for spell in selfSpells:it() do
            local item = TextItem.new('• '..spell:description(), TextStyle.BufferView.Text)
            local indexPath = IndexPath.new(2, currentRow)
            dataSource:addItem(item, indexPath)
            if buffer:is_self_buff_active(spell) then
                self:getDelegate():highlightItemAtIndexPath(item, indexPath)
            end
            currentRow = currentRow + 1
        end
        dataSource:addItem(TextItem.new("", TextStyle.BufferView.Text), IndexPath.new(2, currentRow))
    end

    local partySpells = buffer:get_party_spells()
    if partySpells:length() > 0 then
        dataSource:addItem(TextItem.new("Party Spells", TextStyle.BufferView.Text), IndexPath.new(3, 1))
        local currentRow = 2
        for spell in partySpells:it() do
            dataSource:addItem(TextItem.new('• '..spell:description(), TextStyle.BufferView.Text), IndexPath.new(3, currentRow))
            currentRow = currentRow + 1
        end
    end

    return self
end

return BufferView