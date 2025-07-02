local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local RollSettingsMenuItem = require('ui/settings/menus/rolls/RollSettingsMenuItem')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local CorsairWidget = setmetatable({}, {__index = Widget })
CorsairWidget.__index = CorsairWidget


CorsairWidget.TextSmall3 = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        false
)

function CorsairWidget.new(frame, trust, trustHud, trustSettings, trustSettingsMode, trustModeSettings)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        if item.__type == ImageTextItem.__type then
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(14)
            return cell
        elseif item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(12)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Corsair", dataSource, VerticalFlowLayout.new(2, Padding.new(8, 4, 0, 0), 3), 40, true, 'job'), CorsairWidget)

    self.trust = trust

    local roller = trust:role_with_type("roller")

    self:updateRolls(roller.roll1:get_roll_name(), 0, roller.roll2:get_roll_name(), 0)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)
        coroutine.schedule(function()
            self:resignFocus()
            trustHud:openMenu(RollSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust))
        end, 0.2)
    end), self:getDelegate():didSelectItemAtIndexPath())
    
    self:getDisposeBag():add(roller:on_rolls_changed():addAction(function(roll1Name, roll1Num, roll2Name, roll2Num)
        self:updateRolls(roll1Name, roll1Num, roll2Name, roll2Num)
    end), roller:on_rolls_changed())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function CorsairWidget:updateRolls(roll1Name, roll1Count, roll2Name, roll2Count)
    local roller = self.trust:role_with_type("roller")

    local activeRollName = roller:get_current_roll_id() and res.job_abilities[roller:get_current_roll_id()].en

    for roll in L{ { rollNum = 1, rollName = roll1Name, rollCount = roll1Count }, { rollNum = 2, rollName = roll2Name, rollCount = roll2Count } }:it() do
        local image_item = ImageItem.new(windower.addon_path..'assets/buffs/312.png', 14, 14)

        if roll.rollName == activeRollName then
            image_item:setAlpha(255)
        else
            image_item:setAlpha(100)
        end

        local item = ImageTextItem.new(image_item, TextItem.new(string.format("%s: %d", roll.rollName:gsub(" Roll", ""), roll.rollCount or 0), CorsairWidget.TextSmall3), 2, { x = 0, y = 1 })
        self:getDataSource():updateItem(item, IndexPath.new(1, roll.rollNum))
    end
end

return CorsairWidget