
local ListView = require('cylibs/ui/list_view')
local ListItemView = require('cylibs/ui/list_item_view')
local ListItem = require('cylibs/ui/list_item')
local HorizontalListlayout = require('cylibs/ui/layouts/horizontal_list_layout')
local VerticalListlayout = require('cylibs/ui/layouts/vertical_list_layout')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local ValueRelay = require('cylibs/events/value_relay')

local Event = require('cylibs/events/Luvent')
local TrustActionHud = require('ui/TrustActionHud')
local View = require('cylibs/ui/view')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

function ListView:onEnabledClick()
    return self.enabledClick
end

function TrustHud.new(player, action_queue, addon_enabled)
    local self = setmetatable(View.new(), TrustHud)

    self.actionView = TrustActionHud.new(action_queue)

    self.tabbed_view = TabbedView.new()
    self.tabbed_view:set_pos(500, 200)
    self.tabbed_view:set_size(500, 500)
    self.tabbed_view:set_visible(false)

    self.listView = ListView.new(HorizontalListlayout.new(25, 5))

    self.listView:addItem(ListItem.new({text = '', width = 250, settings = T{text = {red = 255, green = 128, blue = 128, font = 'Arial', size = 14, stroke = {width = 2, alpha = 150}}}}, "Target", TextListItemView.new))
    self.listView:addItem(ListItem.new({text = player.main_job_name_short, width = 60}, "MainJobButton", TextListItemView.new))
    self.listView:addItem(ListItem.new({text = '/', width = 10}, "Separator", TextListItemView.new))
    self.listView:addItem(ListItem.new({text = player.sub_job_name_short, width = 60}, "SubJobButton", TextListItemView.new))
    self.listView:addItem(ListItem.new({text = '', width = 20}, "Spacer", TextListItemView.new))
    self.listView:addItem(ListItem.new({text = 'ON', width = 105, pattern = 'Trust: ${text}'}, "AddonEnabled", TextListItemView.new))

    self.listView:onClick():addAction(function(item)
        if item:getIdentifier() == "AddonEnabled" then
            addon_enabled:setValue(not addon_enabled:getValue())
        elseif item:getIdentifier() == "MainJobButton" then
            if not self.tabbed_view:is_visible() then
                self:updateTabbedView(player.trust.main_job)
            end
            self.tabbed_view:set_visible(not self.tabbed_view:is_visible())
            self.tabbed_view:render()
        elseif item:getIdentifier() == "SubJobButton" then
            if not self.tabbed_view:is_visible() then
                self:updateTabbedView(player.trust.sub_job)
            end
            self.tabbed_view:set_visible(not self.tabbed_view:is_visible())
            self.tabbed_view:render()
        end
    end)

    player.party:on_party_target_change():addAction(function(_, target_index)
        local item = self.listView:getItem("Target")
        if target_index == nil then
            item.data.text = ''
        else
            local target = windower.ffxi.get_mob_by_index(target_index)
            item.data.text = target.name
        end
        self.listView:updateItemView(item)
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

function TrustHud:updateTabbedView(trust)
    self.tabbed_view:removeAllViews()

    for role in trust:get_roles():it() do
        local role_details = role:tostring()
        if role_details then
            local view = ListView.new(VerticalListlayout.new(500, 0))
            view:addItem(ListItem.new({text = role_details, height = 500, settings = T{text = {font = 'Arial', size = 12, stroke = {width = 1, alpha = 150}}, flags = {bold = false}}}, role:get_type(), TextListItemView.new))

            self.tabbed_view:addView(view, role:get_type())

            view:render()
        end
    end

    self.tabbed_view:switchToTab(1)
    self.tabbed_view:set_visible(false)
    self.tabbed_view:render()
end

return TrustHud
