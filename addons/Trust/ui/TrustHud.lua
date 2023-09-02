
local ListView = require('cylibs/ui/list_view')
local ListItemView = require('cylibs/ui/list_item_view')
local ListItem = require('cylibs/ui/list_item')
local ListViewItemStyle = require('cylibs/ui/style/list_view_item_style')
local HorizontalListlayout = require('cylibs/ui/layouts/horizontal_list_layout')
local Mouse = require('cylibs/ui/input/mouse')
local VerticalListlayout = require('cylibs/ui/layouts/vertical_list_layout')
local TabItem = require('cylibs/ui/tabs/tab_item')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local ValueRelay = require('cylibs/events/value_relay')

local Event = require('cylibs/events/Luvent')
local TrustActionHud = require('ui/TrustActionHud')
local View = require('cylibs/ui/view')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

input = Mouse.new()

function ListView:onEnabledClick()
    return self.enabledClick
end

function TrustHud.new(player, action_queue, addon_enabled)
    local self = setmetatable(View.new(), TrustHud)

    self.actionView = TrustActionHud.new(action_queue)

    self.tabbed_view = nil

    self.listView = ListView.new(HorizontalListlayout.new(40, 5))

    local listItems = L{
        ListItem.new({text = '', width = 250}, ListViewItemStyle.DarkMode.Header, "Target", TextListItemView.new),
        ListItem.new({text = player.main_job_name_short, width = 60}, ListViewItemStyle.DarkMode.Header, "MainJobButton", TextListItemView.new),
        ListItem.new({text = '/', width = 10}, ListViewItemStyle.DarkMode.Header, "Separator", TextListItemView.new),
        ListItem.new({text = player.sub_job_name_short, width = 60}, ListViewItemStyle.DarkMode.Header, "SubJobButton", TextListItemView.new),
        ListItem.new({text = '', width = 20}, ListViewItemStyle.DarkMode.Header, "Spacer", TextListItemView.new),
        ListItem.new({text = 'ON', width = 105, pattern = 'Trust: ${text}'}, ListViewItemStyle.DarkMode.Header, "AddonEnabled", TextListItemView.new)
    }

    self.listView:addItems(listItems)

    self.listView:onClick():addAction(function(item)
        if item:getIdentifier() == "AddonEnabled" then
            addon_enabled:setValue(not addon_enabled:getValue())
        elseif item:getIdentifier() == "MainJobButton" then
            self:toggleMenu(player.trust.main_job)
        elseif item:getIdentifier() == "SubJobButton" then
            self:toggleMenu(player.trust.sub_job)
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

    local info = windower.get_windower_settings()

    self.actionView:get_view():pos(-340, y + height + 15)
    self.actionView:render()
end

function TrustHud:toggleMenu(trust)
    if self.tabbed_view then
        self.tabbed_view:destroy()
        self.tabbed_view = nil
    else
        local tabItems = L{}

        -- Roles
        for role in trust:get_roles():it() do
            local role_details = role:tostring()
            if role_details then
                local view = ListView.new(VerticalListlayout.new(500, 0))
                view:addItem(ListItem.new({text = role_details, height = 500}, ListViewItemStyle.DarkMode.Text, role:get_type(), TextListItemView.new))

                tabItems:append(TabItem.new(role:get_type(), view))
            end
        end

        -- Modes
        local modeNames = L(T(state):keyset()):sort()
        local modeTabs = L{}
        local modeTab = L{}

        for modeName in modeNames:it() do
            if modeTab:length() < 19 then
                modeTab:append(ListItem.new({text = modeName..': '..state[modeName].value, mode = state[modeName], modeName = modeName, height = 20}, ListViewItemStyle.DarkMode.TextSmall, modeName, TextListItemView.new))
            else
                modeTabs:append(modeTab)
                modeTab = L{}
                modeTab:append(ListItem.new({text = modeName..': '..state[modeName].value, mode = state[modeName], modeName = modeName, height = 20}, ListViewItemStyle.DarkMode.TextSmall, modeName, TextListItemView.new))
            end
        end
        if modeTab:length() > 0 then
            modeTabs:append(modeTab)
        end

        local modeTabIndex = 1
        for modeTab in modeTabs:it() do
            local modesView = ListView.new(VerticalListlayout.new(380, 0))
            modesView:addItems(modeTab)

            tabItems:append(TabItem.new("Modes "..modeTabIndex, modesView))

            modeTabIndex = modeTabIndex + 1

            modesView:onClick():addAction(function(item)
                item.data.mode:cycle()
                item.data.text = item.data.modeName..': '..state[item.data.modeName].value
                modesView:updateItemView(item)
            end)
        end

        self.tabbed_view = TabbedView.new(tabItems)
        self.tabbed_view:set_pos(500, 200)
        self.tabbed_view:set_size(500, 500)
        self.tabbed_view:set_color(150, 0, 0, 0)

        self.tabbed_view:set_visible(true)
        self.tabbed_view:render()
    end
end

return TrustHud
