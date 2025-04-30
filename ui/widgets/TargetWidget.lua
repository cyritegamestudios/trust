local ActionQueue = require('cylibs/actions/action_queue')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local CollectionViewStyle = require('cylibs/ui/collection_view/collection_view_style')
local Color = require('cylibs/ui/views/color')
local ContainerCollectionViewCell = require('cylibs/ui/collection_view/cells/container_collection_view_cell')
local DisposeBag = require('cylibs/events/dispose_bag')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local MenuItem = require('cylibs/ui/menu/menu_item')
local monster_util = require('cylibs/util/monster_util')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewItem = require('cylibs/ui/collection_view/items/view_item')
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

TargetWidget.TextClaimed = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.red,
        Color.red,
        0,
        1,
        Color.black:withAlpha(175),
        true,
        Color.red,
        true
)

TargetWidget.TextSmall3 = TextStyle.new(
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

function TargetWidget.new(frame, party, trust)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.row == 1 then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(false)
            return cell
        elseif indexPath.row == 2 then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(true)
            return cell
        elseif indexPath.row == 3 then
            local cell = MarqueeCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(false)
            return cell
        elseif indexPath.row == 4 then
            local cell = ContainerCollectionViewCell.new(item)
            cell:setItemSize(item.viewSize or 14)
            cell:setUserInteractionEnabled(false)
            return cell
        elseif indexPath.row == 5 then
            local cell = ContainerCollectionViewCell.new(item)
            cell:setItemSize(item.viewSize or 32)
            cell:setUserInteractionEnabled(false)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Target", dataSource, VerticalFlowLayout.new(2, Padding.new(8, 4, 0, 0), 4), 30), TargetWidget)

    self.actionQueue = ActionQueue.new(nil, false, 5, false, true)
    self.actionDisposeBag = DisposeBag.new()
    self.party = party
    self.alliance = player.alliance
    self.debuffsView = self:createDebuffsView()
    self.maxNumDebuffs = 7
    self.needsResize = true
    self.targetDisposeBag = DisposeBag.new()

    local itemsToAdd = L{
        IndexedItem.new(TextItem.new("", TargetWidget.Text), IndexPath.new(1, 1)),
        IndexedItem.new(TextItem.new("", TargetWidget.TextSmall3), IndexPath.new(1, 2)),
        IndexedItem.new(TextItem.new("", TargetWidget.Subheadline), IndexPath.new(1, 3)),
        IndexedItem.new(ViewItem.new(self.debuffsView, true, 14), IndexPath.new(1, 4)),
    }
    self:getDataSource():addItems(itemsToAdd)

    self:setAllowsMultipleSelection(true)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)
        if indexPath.section == 1 and indexPath.row == 2 then
            coroutine.schedule(function()
                self:showTargetInfo()
            end, 0.2)
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self.actionQueue:on_action_start():addAction(function(_, s)
        self:setAction(s:tostring() or '')
    end), self.actionQueue:on_action_start())

    self:getDisposeBag():add(self.actionQueue:on_action_end():addAction(function(_, s)
        self:setAction('')
    end), self.actionQueue:on_action_end())

    self:getDisposeBag():add(party.target_tracker:on_targets_changed():addAction(function(t, targets_added, targets_removed)
        if self.target_index and targets_added:map(function(t)
            return t:get_index()
        end):contains(self.target_index) then
            self:setTarget(self.target_index)
        end
    end), party.target_tracker:on_targets_changed())

    self:getDisposeBag():add(party:on_party_target_change():addAction(function(_, target_index, _)
        self:setAction('')
        self:setTarget(target_index)
    end, party:on_party_target_change()))

    local current_target = party:get_current_party_target()
    if current_target then
        self:setTarget(current_target:get_mob().index)
    else
        self:setTarget(nil)
    end
    self:setAction(nil)

    local skillchainer = trust:role_with_type("skillchainer")

    self:getDisposeBag():add(skillchainer:on_skillchain():addAction(function(target_id, step)
        --self.actionQueue:clear()
        if --[[skillchainer:get_target() and skillchainer:get_target():get_id()]] self.target_index and monster_util.id_for_index(self.target_index) == target_id then
            self.actionDisposeBag:destroy()
            local element = step:get_skillchain():get_name()
            --local text = "St. "..step:get_step()..": "..element-- "Step %d: %s":format(step:get_step(), element)
            local text = element-- "Step %d: %s":format(step:get_step(), element)
            self:setAction(text)

            self.actionTimer = Timer.scheduledTimer(0.5, 3)

            self.actionDisposeBag:add(self.actionTimer:onTimeChange():addAction(function(_)
                local timeRemaining = math.floor(step:get_time_remaining() + 0.5)
                if timeRemaining > 0 then
                    self:setAction(text..' ('..timeRemaining..'s)')
                else
                    self:setAction(text)
                end
            end), self.actionTimer:onTimeChange())

            self.actionTimer:start()

            self.actionDisposeBag:addAny(L{ self.actionTimer })

            --local skillchain_step_action = BlockAction.new(function()
            --    coroutine.sleep(math.max(1, step:get_time_remaining()))
            --end, element..step:get_step(), text)
            --self.actionQueue:push_action(skillchain_step_action, true)
        end
    end), skillchainer:on_skillchain())

    self:getDisposeBag():add(skillchainer:on_skillchain_ended():addAction(function(target_id)
        if self.target_index and monster_util.id_for_index(self.target_index) == target_id then
            self.actionDisposeBag:destroy()
            self:setAction('')
            --self.actionQueue:clear()
        end
    end), skillchainer:on_skillchain_ended())

    return self
end

function TargetWidget:showTargetInfo()
    if self.target_index == nil then
        return
    end
    local target = self.alliance:get_target_by_index(self.target_index)
    if target then
        local targetInfoMenuItem = MenuItem.new(L{
            ButtonItem.default('Info', 18),
        }, {},
            function(_)
                local TargetInfoView = require('cylibs/battle/monsters/ui/target_info_view')
                local targetInfoView = TargetInfoView.new(target)
                targetInfoView:setShouldRequestFocus(true)
                return targetInfoView
            end, "Targets", "View info on the selected target.", false, function()
                return self.selectedTargetIndex and self.targets[self.selectedTargetIndex]
            end)
        hud:openMenu(targetInfoMenuItem)
    end
end

function TargetWidget:setTarget(target_index)
    self.target_index = target_index

    self.actionDisposeBag:dispose()
    self.targetDisposeBag:dispose()

    local targetText = ""
    if target_index ~= nil and target_index ~= 0 then
        local target = self.alliance:get_target_by_index(target_index)
        if target then
            for event in L{ target:on_gain_debuff(), target.debuff_tracker:on_lose_debuff() }:it() do
                self.targetDisposeBag:add(event:addAction(function(_, _)
                    self:updateDebuffs()
                end), event)
            end

            local infoTimer = Timer.scheduledTimer(0.1)

            self.targetDisposeBag:add(infoTimer:onTimeChange():addAction(function()
                self:setInfo(target:get_hpp(), target:get_distance():sqrt(), target:get_claim_id() and target:get_claim_id() ~= 0)
            end), infoTimer:onTimeChange())
            self.targetDisposeBag:addAny(L{ infoTimer })

            infoTimer:start()

            self:setInfo(target:get_hpp(), target:get_distance():sqrt(), target:get_claim_id() and target:get_claim_id() ~= 0)
        else
            target = Monster.new(monster_util.id_for_index(target_index))

            self.targetDisposeBag:addAny(L{ target })
        end
        targetText = localization_util.truncate(target and target.name or "", 18)
    else
        self:getDelegate():deselectAllItems()
    end

    local targetItem = TextItem.new(targetText, TargetWidget.Text), IndexPath.new(1, 1)
    targetItem:setShouldWordWrap(false)

    self:getDataSource():updateItem(targetItem, IndexPath.new(1, 1))

    self:setVisible(not targetText:empty())

    self:setExpanded(self:shouldExpand())

    self:layoutIfNeeded()
end

function TargetWidget:setClaimed(claimed)
    if claimed then
        self:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
    else
        self:getDelegate():deselectItemAtIndexPath(IndexPath.new(1, 1))
    end
end

function TargetWidget:setInfo(hpp, distance, claimed)
    local itemsToUpdate = L{}

    itemsToUpdate:append(IndexedItem.new(TextItem.new(string.format("HP %d%%  %.1f", hpp, distance), TargetWidget.TextSmall3), IndexPath.new(1, 2)))

    local textItem = self:getDataSource():itemAtIndexPath(IndexPath.new(1, 1))

    local cell = self:getDataSource():cellForItemAtIndexPath(IndexPath.new(1, 1))
    if claimed then
        cell:setTextColor(Color.red)
        itemsToUpdate:append(IndexedItem.new(TextItem.new(textItem:getText(), TargetWidget.TextClaimed), IndexPath.new(1, 1)))
    else
        cell:setTextColor(Color.yellow)
        itemsToUpdate:append(IndexedItem.new(TextItem.new(textItem:getText(), TargetWidget.Text), IndexPath.new(1, 1)))
    end

    self:getDataSource():updateItems(itemsToUpdate)
end

function TargetWidget:setAction(text)
    local actionItem = TextItem.new(text or '', TargetWidget.Subheadline), IndexPath.new(1, 3)

    self:getDataSource():updateItem(actionItem, IndexPath.new(1, 3))
    self:layoutIfNeeded()
end

function TargetWidget:setVisible(visible)
    if self.target_index == nil then
        visible = false
    end
    Widget.setVisible(self, visible)
end

function TargetWidget:setExpanded(expanded)
    local target = self.alliance:get_target_by_index(self.target_index)
    if not target then
        expanded = false
    end
    if not Widget.setExpanded(self, expanded) and not self.needsResize then
        return false
    end
    self.needsResize = false

    -- Debuffs view
    local indexPath = IndexPath.new(1, 4)

    local itemSize = 14
    if expanded and L(target.debuff_tracker:get_debuff_ids()):length() > 0 then
        itemSize = 14
    else
        itemSize = 0
    end
    self:getDataSource():updateItem(ViewItem.new(self.debuffsView, true, itemSize), indexPath)

    self:setSize(self:getSize().width, self:getContentSize().height)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function TargetWidget:shouldExpand()
    local target = self.alliance:get_target_by_index(self.target_index)
    if not target then
        return false
    end
    return L(target.debuff_tracker:get_debuff_ids()):length() > 0 or target:has_resistance_info()
end

function TargetWidget:createDebuffsView(target)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = ImageCollectionViewCell.new(item)
        cell:setItemSize(14)
        return cell
    end)
    local collectionView = CollectionView.new(dataSource, HorizontalFlowLayout.new(2, Padding.equal(0)), nil, CollectionViewStyle.empty())
    collectionView:setScrollEnabled(false)

    local itemsToAdd = L{}
    for i = 1, self.maxNumDebuffs or 7 do
        itemsToAdd:append(IndexedItem.new(ImageItem.new('', 20, 20), IndexPath.new(1, i)))
    end
    dataSource:addItems(itemsToAdd)

    return collectionView
end

function TargetWidget:updateDebuffs()
    local target = self.alliance:get_target_by_index(self.target_index)
    if not target then
        return
    end
    local itemsToUpdate = L{}

    local allDebuffIds = L(target.debuff_tracker:get_debuff_ids())
    for i = 1, self.maxNumDebuffs do
        local debuffId = allDebuffIds[i]
        -- Sluggish Daze Lv.6-10
        if S{700,701,702,703,704}:contains(debuffId) then
            debuffId = 395 -- Sluggish Daze Lv.5
        end
        if debuffId then
            itemsToUpdate:append(IndexedItem.new(ImageItem.new(windower.addon_path..'assets/buffs/'..debuffId..'.png', 14, 14), IndexPath.new(1, i)))
        else
            itemsToUpdate:append(IndexedItem.new(ImageItem.new('', 14, 14), IndexPath.new(1, i)))
        end
    end

    self.debuffsView:getDataSource():updateItems(itemsToUpdate)

    self.needsResize = true

    self:setExpanded(allDebuffIds:length() > 0)
end

return TargetWidget