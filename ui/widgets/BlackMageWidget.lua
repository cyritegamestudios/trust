local Avatar = require('cylibs/entity/avatar')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local PickerCollectionViewCell = require('cylibs/ui/collection_view/cells/picker_collection_view_cell')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local PickerItem = require('cylibs/ui/collection_view/items/picker_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local BlackMageWidget = setmetatable({}, {__index = Widget })
BlackMageWidget.__index = BlackMageWidget


BlackMageWidget.TextSmall = TextStyle.new(
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
BlackMageWidget.TextSmall3 = TextStyle.new(
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
BlackMageWidget.Subheadline = TextStyle.new(
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

function BlackMageWidget.new(frame, addonSettings, player, trust, trustHud, trustSettings, trustSettingsMode)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item, BlackMageWidget.TextSmall3)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(13)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Black Mage", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 75, true), BlackMageWidget)

    self.addonSettings = addonSettings
    self.id = player:get_id()
    self.actionDisposeBag = DisposeBag.new()
    self.targetDisposeBag = DisposeBag.new()

    self:setUserInteractionEnabled(true)

    self:getDataSource():addItem(TextItem.new("Stoneja Lv.1", BlackMageWidget.TextSmall3), IndexPath.new(1, 1))

    self:getDisposeBag():add(trust:get_party():on_party_target_change():addAction(function(_, target_index, _)
        local target = trust:get_party():get_target_by_index(target_index)
        self:setTarget(target)
    end, trust:get_party():on_party_target_change()))

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        --self:getDelegate():deselectItemAtIndexPath(indexPath)

    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)

    end), self:getDelegate():didDeselectItemAtIndexPath())

    self:setEffect(nil)

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function BlackMageWidget:getSettings(addonSettings)
    return addonSettings:getSettings().black_mage_widget
end

function BlackMageWidget:setEffect(cumulativeEffect)
    self.actionDisposeBag:dispose()

    if cumulativeEffect then
        local effectText = cumulativeEffect:get_spell_name().." Lv."..cumulativeEffect:get_level()

        self.actionTimer = Timer.scheduledTimer(1.0, 0)

        local getTextForEffect = function(cumulativeEffect)
            local timeRemaining = cumulativeEffect:get_time_remaining()
            if timeRemaining > 0 then
                return effectText..' ('..timeRemaining..'s)'
            else
                return effectText
            end
        end

        local actionItem = TextItem.new(getTextForEffect(cumulativeEffect), BlackMageWidget.TextSmall3), IndexPath.new(1, 1)
        self:getDataSource():updateItem(actionItem, IndexPath.new(1, 1))

        self.actionDisposeBag:add(self.actionTimer:onTimeChange():addAction(function(_)
            local actionItem = TextItem.new(getTextForEffect(cumulativeEffect), BlackMageWidget.TextSmall3), IndexPath.new(1, 1)
            self:getDataSource():updateItem(actionItem, IndexPath.new(1, 1))
        end), self.actionTimer:onTimeChange())

        self.actionTimer:start()

        self.actionDisposeBag:addAny(L{ self.actionTimer })

        self:setVisible(true)
    else
        local actionItem = TextItem.new('', BlackMageWidget.TextSmall3), IndexPath.new(1, 1)
        self:getDataSource():updateItem(actionItem, IndexPath.new(1, 1))

        self:setVisible(false)
    end

    self:layoutIfNeeded()
end

function BlackMageWidget:setTarget(target)
    self.target = target

    self.targetDisposeBag:dispose()

    if self.target then
        self.targetDisposeBag:add(self.target.cumulative_magic_tracker:on_gain_cumulative_effect():addAction(function(_, effect)
            self:setEffect(effect)
        end), self.target.cumulative_magic_tracker:on_gain_cumulative_effect())

        self.targetDisposeBag:add(self.target.cumulative_magic_tracker:on_lose_cumulative_effect():addAction(function(_, effect)
            self:setEffect(nil)
        end), self.target.cumulative_magic_tracker:on_lose_cumulative_effect())

        self:setEffect(self.target:get_cumulative_effect())
    else
        self:setEffect(nil)
    end
end

return BlackMageWidget