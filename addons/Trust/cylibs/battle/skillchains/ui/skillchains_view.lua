local buff_util = require('cylibs/util/buff_util')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local SkillchainsView = setmetatable({}, {__index = CollectionView })
SkillchainsView.__index = SkillchainsView

function SkillchainsView.new(skillchainer)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), SkillchainsView)

    local modeNames = L{'AutoSkillchainMode', 'SkillchainPartnerMode', 'SkillchainPriorityMode', 'SkillchainDelayMode', 'AutoAftermathMode'}
    for modeName in modeNames:it() do
        local mode = state[modeName]
        if mode then
            self:getDisposeBag():add(mode:on_state_change():addAction(function(mode, newValue)
               self:reload(modeNames)
            end), mode:on_state_change())
        end
    end

    self:reload(modeNames)

    return self
end

function SkillchainsView:reload(modeNames)
    self:getDataSource():removeAllItems()

    local itemsToAdd = L{}

    local currentSection = 1
    for modeName in modeNames:it() do
        local mode = state[modeName]
        if mode then
            local description = mode:get_description(mode.value)
            if description and description:length() > 0 then
                itemsToAdd:append(IndexedItem.new(TextItem.new(mode:get_description() or modeName, TextStyle.Default.HeaderSmall), IndexPath.new(currentSection, 1)))

                local text = string.gsub(description, "Okay, ", "")

                itemsToAdd:append(IndexedItem.new(TextItem.new(text, TextStyle.Default.TextSmall), IndexPath.new(currentSection, 2)))
                itemsToAdd:append(IndexedItem.new(TextItem.new("", TextStyle.Default.TextSmall), IndexPath.new(currentSection, 3)))

                currentSection = currentSection + 1
            end
        end
    end

    self:getDataSource():addItems(itemsToAdd)
end

return SkillchainsView