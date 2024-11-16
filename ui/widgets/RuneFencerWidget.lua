local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local RuneFencerWidget = setmetatable({}, {__index = Widget })
RuneFencerWidget.__index = RuneFencerWidget


RuneFencerWidget.TextSmall = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        true
)
RuneFencerWidget.TextSmall3 = TextStyle.new(
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
RuneFencerWidget.Subheadline = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.lightGrey,
        0,
        0.5,
        Color.black,
        true,
        Color.red
)

function RuneFencerWidget.new(frame, addonSettings, trust)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.row == 1 then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(15)
            cell:setUserInteractionEnabled(true)
            return cell
        else
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setItemSize(10)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Rune Fencer", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 90, true), RuneFencerWidget)

    self.addonSettings = addonSettings
    self.trust = trust
    self.actionDisposeBag = DisposeBag.new()

    self:getDataSource():addItem(TextItem.new(state.AutoRuneMode.value, RuneFencerWidget.TextSmall3), IndexPath.new(1, 1))

    self:setRune(state.AutoRuneMode.value)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)

        handle_cycle('AutoRuneMode')

        self:getDataSource():updateItem(TextItem.new(state.AutoRuneMode.value, RuneFencerWidget.TextSmall3), IndexPath.new(1, 1))

        self:layoutIfNeeded()
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(state.AutoRuneMode:on_state_change():addAction(function(m, newValue, _)
        self:setRune(newValue)
    end), state.AutoRuneMode:on_state_change())

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:layoutIfNeeded()

    return self
end

function RuneFencerWidget:destroy()
    Widget.destroy(self)
end

function RuneFencerWidget:getSettings(addonSettings)
    return addonSettings:getSettings().rune_fencer_widget
end

function RuneFencerWidget:setRune(rune)
    local elementId, resistance = self.trust:get_job():get_resistance_for_rune(rune)
    if elementId ~= 15 then
        local textItem = TextItem.new(resistance.."+", TextStyle.Default.Subheadline)
        textItem:setOffset(-2, -5)

        self:getDataSource():updateItem(ImageTextItem.new(AssetManager.imageItemForElement(elementId), textItem, 0), IndexPath.new(1, 2))
    else
        self:getDataSource():removeItem(IndexPath.new(1, 2))
    end
    self:layoutIfNeeded()
end

return RuneFencerWidget