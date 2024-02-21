local ActionQueue = require('cylibs/actions/action_queue')
local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local skillchain_util = require('cylibs/util/skillchain_util')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local TargetWidget = setmetatable({}, {__index = Widget })
TargetWidget.__index = TargetWidget

TargetWidget.Text = TextStyle.new(
    Color.clear,
    Color.clear,
    "Arial",
    9,
    Color.yellow,
    Color.yellow,
    0,
    1,
    Color.black:withAlpha(175),
    true,
    Color.red,
    true
)

TargetWidget.Subheadline = TextStyle.new(
    Color.clear,
    Color.clear,
    "Arial",
    8,
    Color.white,
    Color.yellow,
    0,
    0.5,
    Color.black,
    true,
    Color.red
)

function TargetWidget.new(frame, addonSettings, party, trust)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == TextItem.__type then
            if indexPath.row == 1 then
                local cell = TextCollectionViewCell.new(item)
                cell:setItemSize(14)
                cell:setUserInteractionEnabled(false)
                return cell
            else
                local cell = MarqueeCollectionViewCell.new(item)
                cell:setItemSize(14)
                cell:setUserInteractionEnabled(false)
                return cell
            end
        end
    end)

    local self = setmetatable(Widget.new(frame, "Target", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(8, 4, 0, 0), 4), 30), TargetWidget)

    self.addonSettings = addonSettings
    self.actionQueue = ActionQueue.new(nil, false, 5, false, true)
    self.party = party
    self.targetDisposeBag = DisposeBag.new()

    self:getDataSource():addItem(TextItem.new("", TargetWidget.Text), IndexPath.new(1, 1))

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(self.actionQueue:on_action_start():addAction(function(_, s)
        self:setAction(s:tostring() or '')
    end), self.actionQueue:on_action_start())

    self:getDisposeBag():add(self.actionQueue:on_action_end():addAction(function(_, s)
        self:setAction('')
    end), self.actionQueue:on_action_end())

    self:getDisposeBag():add(party:on_party_target_change():addAction(function(_, target_index, _)
        self:setTarget(target_index)
    end, party:on_party_target_change()))

    self:setTarget(nil)
    self:setAction(nil)

    local skillchainer = trust:role_with_type("skillchainer")

    self:getDisposeBag():add(skillchainer:on_skillchain():addAction(function(target_id, step)
        self.actionQueue:clear()
        if skillchainer:get_target() and skillchainer:get_target():get_id() == target_id then
            local element = step:get_skillchain():get_name()
            local text = "Step "..step:get_step()..": "..element-- "Step %d: %s":format(step:get_step(), element)
            local skillchain_step_action = BlockAction.new(function()
                coroutine.sleep(math.max(1, step:get_time_remaining()))
            end, element..step:get_step(), text)
            self.actionQueue:push_action(skillchain_step_action, true)
        end
    end), skillchainer:on_skillchain())

    self:getDisposeBag():add(skillchainer:on_skillchain_ended():addAction(function(target_id)
        if skillchainer:get_target() and skillchainer:get_target():get_id() == target_id then
            self.actionQueue:clear()
        end
    end), skillchainer:on_skillchain_ended())

    return self
end

function TargetWidget:getSettings(addonSettings)
    return addonSettings:getSettings().target_widget
end

function TargetWidget:setTarget(target_index)
    self.target_index = target_index

    self.targetDisposeBag:dispose()

    local targetText = ""
    if target_index ~= nil then
        local target = self.party:get_target_by_index(target_index)
        --[[if target then
            self.targetDisposeBag:add(target:on_skillchain():addAction(function(_, step)
                self.actionQueue:clear()
                local element = step:get_skillchain():get_name()
                local text = "Step %s: %s":format(step:get_step(), element)
                local skillchain_step_action = BlockAction.new(function()
                    coroutine.sleep(math.max(1, step:get_time_remaining()))
                end, element..step:get_step(), text)
                self.actionQueue:push_action(skillchain_step_action, true)
            end), target:on_skillchain())

            self.targetDisposeBag:add(target:on_skillchain_ended():addAction(function(_, step)
                self.actionQueue:clear()
            end), target:on_skillchain_ended())
        end]]
        targetText = target and target.name or ""
    end

    local targetItem = TextItem.new(targetText, TargetWidget.Text), IndexPath.new(1, 1)
    targetItem:setShouldWordWrap(false)

    self:getDataSource():updateItem(targetItem, IndexPath.new(1, 1))

    self:setVisible(not targetText:empty())
    self:layoutIfNeeded()
end

function TargetWidget:setAction(text)
    local actionItem = TextItem.new(text or '', TargetWidget.Subheadline), IndexPath.new(1, 2)

    self:getDataSource():updateItem(actionItem, IndexPath.new(1, 2))
    self:layoutIfNeeded()
end

function TargetWidget:setVisible(visible)
    if self.target_index == nil then
        visible = false
    end
    Widget.setVisible(self, visible)
end

return TargetWidget