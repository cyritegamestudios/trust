local BufferView = require('cylibs/trust/roles/ui/buffer_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DebufferView = require('cylibs/trust/roles/ui/debuffer_view')
local DebugView = require('cylibs/actions/ui/debug_view')
local Frame = require('cylibs/ui/views/frame')
local HelpView = require('cylibs/trust/ui/help_view')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local ModesAssistantView = require('cylibs/modes/ui/modes_assistant_view')
local ModesView = require('cylibs/modes/ui/modes_view')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local Mouse = require('cylibs/ui/input/mouse')
local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
local party_util = require('cylibs/util/party_util')
local SkillchainsView = require('cylibs/battle/skillchains/ui/skillchains_view')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local TrustActionHud = require('cylibs/actions/ui/action_hud')
local View = require('cylibs/ui/views/view')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

function TrustHud:onEnabledClick()
    return self.enabledClick
end

TextStyle.TargetView = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        12,
        Color.white,
        Color.red,
        2,
        1,
        255,
        true
)

function TrustHud.new(player, action_queue, addon_enabled)
    local self = setmetatable(View.new(), TrustHud)

    self.actionView = TrustActionHud.new(action_queue)

    self:addSubview(self.actionView)

    self.tabbed_view = nil

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        local cellSize = 60
        if indexPath.row == 1 then
            cellSize = 250
        else
            cell:setUserInteractionEnabled(true)
        end
        cell:setItemSize(cellSize)
        return cell
    end)

    self.listView = CollectionView.new(dataSource, HorizontalFlowLayout.new(5))
    self.listView.frame.height = 25

    self:addSubview(self.listView)

    dataSource:addItem(TextItem.new('', TextStyle.TargetView), IndexPath.new(1, 1))
    dataSource:addItem(TextItem.new(player.main_job_name_short, TextStyle.Default.Button), IndexPath.new(1, 2))
    dataSource:addItem(TextItem.new(player.sub_job_name_short, TextStyle.Default.Button), IndexPath.new(1, 3))
    dataSource:addItem(TextItem.new('ON', TextStyle.Default.Button, "Trust: ${text}"), IndexPath.new(1, 4))

    self:getDisposeBag():add(self.listView:getDelegate():didSelectItemAtIndexPath():addAction(function(item, indexPath)
        self.listView:getDelegate():deselectItemAtIndexPath(item, indexPath)
        if indexPath.row == 2 then
            self:toggleMenu(player.main_job_name_short, player.trust.main_job, player.party, action_queue)
        elseif indexPath.row == 3 then
            self:toggleMenu(player.sub_job_name_short, player.trust.sub_job, player.party, action_queue)
        elseif indexPath.row == 4 then
            addon_enabled:setValue(not addon_enabled:getValue())
        end
    end), self.listView:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(addon_enabled:onValueChanged():addAction(function(_, isEnabled)
        local indexPath = IndexPath.new(1, 4)
        local item = self.listView:getDataSource():itemAtIndexPath(indexPath)
        local newText = ''
        if isEnabled then
            newText = 'ON'
        else
            newText = 'OFF'
        end
        self.listView:getDataSource():updateItem(TextItem.new(newText, item:getStyle(), item:getPattern()), indexPath)
    end), addon_enabled:onValueChanged())

    self:getDisposeBag():add(player.party:on_party_target_change():addAction(function(_, target_index)
        local indexPath = IndexPath.new(1, 1)
        local item = self.listView:getDataSource():itemAtIndexPath(indexPath)

        local newItemDataText = ''
        local isClaimed = false
        if target_index == nil then
            newItemDataText = ''
        else
            local target = windower.ffxi.get_mob_by_index(target_index)
            newItemDataText = target.name
            if party_util.party_claimed(target.id) then
                isClaimed = true
            end
        end
        local cell = self.listView:getDataSource():cellForItemAtIndexPath(indexPath)
        if newItemDataText ~= item:getText() or (cell and cell:isHighlighted() ~= isClaimed) then
            self.listView:getDataSource():updateItem(TextItem.new(newItemDataText, item:getStyle(), item:getPattern()), indexPath)
            if isClaimed then
                self.listView:getDelegate():highlightItemAtIndexPath(item, indexPath)
            end
        end
    end), player.party:on_party_target_change())

    return self
end

function TrustHud:destroy()
    if self.events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.click:removeAllEvents()
    self.layout:destroy()

    for _, itemView in pairs(self.itemViews) do
        itemView:destroy()
    end
end

function TrustHud:layoutIfNeeded()
    View.layoutIfNeeded(self)

    self.listView:setNeedsLayout()
    self.listView:layoutIfNeeded()

    self.actionView:setPosition(250 + 5, self.listView:getSize().height + 5)
    self.actionView:setNeedsLayout()
    self.actionView:layoutIfNeeded()
end

function TrustHud:toggleMenu(job_name_short, trust, party, action_queue)
    if self.tabbedView then
        self.tabbedView:destroy()
        self.tabbedView = nil
    else
        local tabbedView = TabbedView.new(Frame.new(500, 200, 500, 500))
        tabbedView:setBackgroundColor(Color.black:withAlpha(175))

        tabbedView:addTab(PartyMemberView.new(party), string.upper("party"))

        local buffer = trust:role_with_type("buffer")
        if buffer then
            tabbedView:addTab(BufferView.new(buffer), string.upper("buffs"))
        end

        local debuffer = trust:role_with_type("debuffer")
        if debuffer then
            tabbedView:addTab(DebufferView.new(debuffer, debuffer:get_battle_target()), string.upper("debuffs"))
        end

        local skillchainer = trust:role_with_type("skillchainer")
        if skillchainer then
            tabbedView:addTab(SkillchainsView.new(skillchainer), string.upper("skillchains"))
        end

        local allModeNames = L(T(state):keyset()):sort()
        local splitIndex = math.floor(allModeNames:length() / 2)

        local modes1 = allModeNames:copy():slice(1, splitIndex)
        local modes2 = allModeNames:copy():slice(splitIndex + 1, allModeNames:length())

        tabbedView:addTab(ModesView.new(modes1), string.upper("modes 1"))
        tabbedView:addTab(ModesView.new(modes2), string.upper("modes 2"))
        tabbedView:addTab(ModesAssistantView.new(), string.upper("assistant"))

        tabbedView:addTab(HelpView.new(job_name_short), string.upper("help"))
        tabbedView:addTab(DebugView.new(action_queue), string.upper("debug"))

        tabbedView:selectTab(1)

        tabbedView:setNeedsLayout()
        tabbedView:layoutIfNeeded()

        self.tabbedView = tabbedView
    end
end

return TrustHud
