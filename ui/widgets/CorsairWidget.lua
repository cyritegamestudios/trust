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
            cell:setItemSize(16)
            return cell
        elseif item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(16)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Corsair", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 40, true, 'job'), CorsairWidget)

    self.trust = trust

    local roller = trust:role_with_type("roller")

    self:setRolls(state.AutoRollMode.value, roller:get_is_rolling())

    self:getDisposeBag():add(state.AutoRollMode:on_state_change():addAction(function(_, new_value, _)
        self:setRolls(new_value, roller:get_is_rolling())
    end), state.AutoRollMode:on_state_change())

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)
        coroutine.schedule(function()
            self:resignFocus()
            trustHud:openMenu(RollSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust))
        end, 0.2)
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(roller:on_rolls_begin():addAction(function(_, _)
        self:setRolls(state.AutoRollMode.value, true)
    end, roller:on_rolls_begin()))

    self:getDisposeBag():add(roller:on_rolls_end():addAction(function(_, _)
        self:setRolls(state.AutoRollMode.value, false)
    end, roller:on_rolls_end()))

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function CorsairWidget:setRolls(_, isRolling)
    local text_item = TextItem.new(string.format(state.AutoRollMode.value), CorsairWidget.TextSmall3)
    text_item:setOffset(0, 2)

    local image_item = ImageTextItem.new(ImageItem.new(windower.addon_path..'assets/buffs/312.png', 14, 14), text_item, 2, { x = 0, y = 1 })

    if isRolling then
        image_item:getImageItem():setAlpha(255)
    else
        image_item:getImageItem():setAlpha(100)
    end

    self:getDataSource():updateItem(image_item, IndexPath.new(1, 1))
end

return CorsairWidget