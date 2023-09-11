local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local ModesAssistantView = setmetatable({}, {__index = CollectionView })
ModesAssistantView.__index = ModesAssistantView

function ModesAssistantView.new(main_job_name_short)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(indexPath.row ~= 1)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), ModesAssistantView)

    dataSource:addItem(TextItem.new("What would you like to do?", TextStyle.Default.Text), IndexPath.new(1, 1))
    dataSource:addItem(TextItem.new("• I'd like to engage and stay in combat range.", TextStyle.Default.TextSmall), IndexPath.new(1, 2))
    dataSource:addItem(TextItem.new("• I'd like to stay on the back line.", TextStyle.Default.TextSmall), IndexPath.new(1, 3))
    dataSource:addItem(TextItem.new("• I want to be the main healer.", TextStyle.Default.TextSmall), IndexPath.new(1, 4))
    dataSource:addItem(TextItem.new("• I want to be the backup healer.", TextStyle.Default.TextSmall), IndexPath.new(1, 5))
    dataSource:addItem(TextItem.new("• I want to make skillchains with my party.", TextStyle.Default.TextSmall), IndexPath.new(1, 6))
    dataSource:addItem(TextItem.new("• I want to let my party magic burst.", TextStyle.Default.TextSmall), IndexPath.new(1, 7))

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(item, indexPath)
        local row = indexPath.row
        if indexPath.section == 1 then
            if row == 2 then
                handle_set('AutoEngageMode', 'Always')
                handle_set('CombatMode', 'Melee')
            elseif row == 3 then
                handle_set('AutoEngageMode', 'Off')
                handle_set('CombatMode', 'Ranged')
            elseif row == 4 then
                handle_set('AutoHealMode', 'Auto')
            elseif row == 5 then
                handle_set('AutoHealMode', 'Emergency')
            elseif row == 6 then
                handle_set('AutoSkillchainMode', 'Auto')
                handle_set('SkillchainPartnerMode', 'Auto')
            elseif row == 7 then
                handle_set('AutoSkillchainMode', 'Auto')
                handle_set('SkillchainDelayMode', 'Maximum')
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    return self
end

return ModesAssistantView