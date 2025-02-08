local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local ScholarWidget = setmetatable({}, {__index = Widget })
ScholarWidget.__index = ScholarWidget


ScholarWidget.TextSmall3 = TextStyle.new(
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

function ScholarWidget.new(frame, addonSettings, player, trust)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        if item.__type == ImageTextItem.__type then
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(false)
            cell:setIsSelectable(false)
            cell:setItemSize(16)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Scholar", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 40, true), ScholarWidget)

    self.addonSettings = addonSettings
    self.trust = trust
    self.strategemTimer = Timer.scheduledTimer(5)

    self:getDisposeBag():addAny(L{ self.strategemTimer })

    self:getDisposeBag():add(self.strategemTimer:onTimeChange():addAction(function(_, _)
        self:updateStrategemCount()
    end, self.strategemTimer:onTimeChange()))

    self:getDisposeBag():add(player:on_job_ability_used():addAction(function(_, _)
        coroutine.schedule(function()
            self:updateStrategemCount()
        end, 0.5)
    end, player:on_job_ability_used()))

    self:updateStrategemCount()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self.strategemTimer:start()

    return self
end

function ScholarWidget:getSettings(addonSettings)
    return addonSettings:getSettings().scholar_widget
end

function ScholarWidget:updateStrategemCount()
    if self.trust:get_job():is_light_arts_active() or self.trust:get_job():is_dark_arts_active() then
        self:setVisible(true)

        local image_path
        if self.trust:get_job():is_light_arts_active() then
            image_path = windower.addon_path..'assets/buffs/358.png'
        else
            image_path = windower.addon_path..'assets/buffs/359.png'
        end
        local text_item = TextItem.new(string.format("%d / %d", self.trust:get_job():get_current_num_strategems(), self.trust:get_job():get_max_num_strategems()), ScholarWidget.TextSmall3)
        text_item:setOffset(0, 2)
        local image_item = ImageTextItem.new(ImageItem.new(image_path, 16, 16), text_item)
        self:getDataSource():updateItem(image_item, IndexPath.new(1, 1))
    else
        self:setVisible(false)
    end
    self:layoutIfNeeded()
end

function ScholarWidget:setVisible(visible)
    Widget.setVisible(self, visible)
end

return ScholarWidget