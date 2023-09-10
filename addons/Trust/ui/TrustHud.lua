local BufferView = require('cylibs/trust/roles/ui/buffer_view')
local Button = require('cylibs/ui/button')
local Color = require('cylibs/ui/views/color')
local DebufferView = require('cylibs/trust/roles/ui/debuffer_view')
local DebugView = require('cylibs/actions/ui/debug_view')
local Frame = require('cylibs/ui/views/frame')
local HelpView = require('cylibs/trust/ui/help_view')
local ListView = require('cylibs/ui/list_view')
local ListItemView = require('cylibs/ui/list_item_view')
local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local ModesView = require('cylibs/modes/ui/modes_view')
local HorizontalListlayout = require('cylibs/ui/layouts/horizontal_list_layout')
local Mouse = require('cylibs/ui/input/mouse')
local PartyBufferView = require('cylibs/trust/roles/ui/party_buffer_view')
local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
local party_util = require('cylibs/util/party_util')
local SkillchainsView = require('cylibs/battle/skillchains/ui/skillchains_view')
local VerticalListlayout = require('cylibs/ui/layouts/vertical_list_layout')
local TabItem = require('cylibs/ui/tabs/tab_item')
local TabbedView = require('cylibs/ui/tabs/tabbed_view_v2')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local ValueRelay = require('cylibs/events/value_relay')

local Event = require('cylibs/events/Luvent')
local TrustActionHud = require('cylibs/actions/ui/action_hud')
local View = require('cylibs/ui/view')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

input = Mouse.new()

function TrustHud:onEnabledClick()
    return self.enabledClick
end

function TrustHud.new(player, action_queue, addon_enabled)
    local self = setmetatable(View.new(), TrustHud)

    self.actionView = TrustActionHud.new(action_queue)

    self.tabbed_view = nil

    self.listView = ListView.new(HorizontalListlayout.new(40, 5))

    local listItems = L{
        ListItem.new({text = '', width = 250}, ListViewItemStyle.DarkMode.Header, "Target", TextListItemView.new),
        ListItem.new({text = player.main_job_name_short, highlightable = true, width = 60}, ListViewItemStyle.DarkMode.Header, "MainJobButton", TextListItemView.new),
        ListItem.new({text = '/', width = 10}, ListViewItemStyle.DarkMode.Header, "Separator", TextListItemView.new),
        ListItem.new({text = player.sub_job_name_short, highlightable = true, width = 60}, ListViewItemStyle.DarkMode.Header, "SubJobButton", TextListItemView.new),
        ListItem.new({text = '', width = 20}, ListViewItemStyle.DarkMode.Header, "Spacer", TextListItemView.new),
        ListItem.new({text = 'ON', highlightable = true, width = 105, pattern = 'Trust: ${text}'}, ListViewItemStyle.DarkMode.Header, "AddonEnabled", TextListItemView.new)
    }

    self.listView:addItems(listItems)

    self.listView:onClick():addAction(function(item)
        if item:getIdentifier() == "AddonEnabled" then
            addon_enabled:setValue(not addon_enabled:getValue())
        elseif item:getIdentifier() == "MainJobButton" then
            self:toggleMenu(player.main_job_name_short, player.trust.main_job, player.party, action_queue)
        elseif item:getIdentifier() == "SubJobButton" then
            self:toggleMenu(player.sub_job_name_short, player.trust.sub_job, player.party, action_queue)
        end
    end)

    player.party:on_party_target_change():addAction(function(_, target_index)
        local item = self.listView:getItem("Target")
        local newItemDataText = ''
        if target_index == nil then
            newItemDataText = ''
        else
            local target = windower.ffxi.get_mob_by_index(target_index)
            newItemDataText = target.name
            local itemView = self.listView:getItemView(item)
            if party_util.party_claimed(target.id) then
                local redColor = ListViewItemStyle.TextColor.Red
                itemView:setTextColor(redColor.red, redColor.green, redColor.blue)
            else
                local defaultColor = item:getStyle():getFontColor()
                itemView:setTextColor(defaultColor.red, defaultColor.green, defaultColor.blue)
            end
        end
        if newItemDataText ~= item.data.text then
            item.data.text = newItemDataText
            self.listView:updateItemView(item)
        end
    end)

    addon_enabled:onValueChanged():addAction(function(_, isEnabled)
        local item = self.listView:getItem("AddonEnabled")
        if isEnabled then
            item.data.text = 'ON'
        else
            item.data.text = 'OFF'
        end
        self.listView:updateItemView(item)
    end)

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

function TrustHud:render()
    View.render(self)

    self:set_color(0, 0, 0, 0)

    local x, y = self:get_pos()

    self.listView:set_pos(x, y)
    self.listView:render()

    local _, height = self.listView:get_size()

    self.actionView:set_pos(x + 250 + 10, y + height + 15)
    self.actionView:render()
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
            tabbedView:addTab(BufferView.new(buffer), string.upper("buffer"))
        end

        local debuffer = trust:role_with_type("debuffer")
        if debuffer then
            tabbedView:addTab(DebufferView.new(debuffer, debuffer:get_battle_target()), string.upper("debuffer"))
        end

        local skillchainer = trust:role_with_type("skillchainer")
        if skillchainer then
            tabbedView:addTab(SkillchainsView.new(skillchainer), string.upper("skillchains"))
        end

        local allModeNames = L(T(state):keyset()):sort()
        local splitIndex = math.floor(allModeNames:length() / 2)

        local modes1 = allModeNames:copy():slice(1, splitIndex)
        local modes2 = allModeNames:copy():slice(splitIndex, allModeNames:length())

        tabbedView:addTab(ModesView.new(modes1), string.upper("modes 1"))
        tabbedView:addTab(ModesView.new(modes2), string.upper("modes 2"))

        tabbedView:addTab(HelpView.new(job_name_short), string.upper("help"))

        tabbedView:selectTab(1)

        tabbedView:setNeedsLayout()
        tabbedView:layoutIfNeeded()

        self.tabbedView = tabbedView

        --[[local tabItems = L{}

        -- Party
        tabItems:append(TabItem.new("party", PartyMemberView.new(party, VerticalListlayout.new(380, 0))))

        -- Roles
        local buffer = trust:role_with_type("buffer")
        if buffer then
            tabItems:append(TabItem.new("buffs", BufferView.new(buffer, VerticalListlayout.new(380, 0))))
            --tabItems:append(TabItem.new("party", PartyBufferView.new(buffer, VerticalListlayout.new(380, 0))))
        end

        local debuffer = trust:role_with_type("debuffer")
        if debuffer then
            tabItems:append(TabItem.new("debuffs", DebufferView.new(debuffer, debuffer:get_battle_target(), VerticalListlayout.new(380, 0))))
        end

        -- Modes
        local modeNames = L(T(state):keyset()):sort()
        local modeTabs = L{}
        local modeTab = L{}

        for modeName in modeNames:it() do
            if modeTab:length() < 18 then
                modeTab:append(ListItem.new({text = modeName..': '..state[modeName].value, mode = state[modeName], modeName = modeName, highlightable = true, height = 20}, ListViewItemStyle.DarkMode.TextSmall, modeName, TextListItemView.new))
            else
                modeTabs:append(modeTab)
                modeTab = L{}
                modeTab:append(ListItem.new({text = modeName..': '..state[modeName].value, mode = state[modeName], modeName = modeName, highlightable = true, height = 20}, ListViewItemStyle.DarkMode.TextSmall, modeName, TextListItemView.new))
            end
        end
        if modeTab:length() > 0 then
            modeTabs:append(modeTab)
        end

        local modeTabIndex = 1
        for modeTab in modeTabs:it() do
            local modesView = ModesView.new(VerticalListlayout.new(380, 0))
            modesView:addItems(modeTab)

            tabItems:append(TabItem.new("Modes "..modeTabIndex, modesView))

            modeTabIndex = modeTabIndex + 1
        end

        local skillchainer = trust:role_with_type("skillchainer")
        if skillchainer then
            tabItems:append(TabItem.new("skillchains", SkillchainsView.new(skillchainer, VerticalListlayout.new(380, 0))))
        end

        tabItems:append(TabItem.new("help", HelpView.new(job_name_short, VerticalListlayout.new(380, 0))))
        tabItems:append(TabItem.new("debug", DebugView.new(action_queue, VerticalListlayout.new(380, 0))))

        local info = windower.get_windower_settings()

        self.tabbed_view:setTabItems(tabItems)
        self.tabbed_view:set_pos((info.ui_x_res - 500) / 2, (info.ui_y_res - 500) / 2)
        self.tabbed_view:set_size(500, 500)
        self.tabbed_view:set_color(150, 0, 0, 0)

        self.tabbed_view:set_visible(true)
        self.tabbed_view:render()]]
    end
end

return TrustHud
