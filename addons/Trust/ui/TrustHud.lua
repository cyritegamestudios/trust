
local ListView = require('cylibs/ui/list_view')
local ListItemView = require('cylibs/ui/list_item_view')
local ListItem = require('cylibs/ui/list_item')
local HorizontalListlayout = require('cylibs/ui/layouts/horizontal_list_layout')
local VerticalListlayout = require('cylibs/ui/layouts/vertical_list_layout')
local TextListItemView = require('cylibs/ui/items/text_list_item_view')
local TrustDetailsView = require('ui/TrustDetailsView')
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

    self.detailsView = TrustDetailsView.new(player.trust.main_job, player.main_job_name);
    self.actionView = TrustActionHud.new(action_queue);

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
            self:showDetailsView(player.trust.main_job, player.main_job_name_short)
        elseif item:getIdentifier() == "SubJobButton" then
            self:showDetailsView(player.trust.sub_job, player.sub_job_name_short)
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

function TrustHud:showDetailsView(trust, trust_job_name)
    if self.detailsView:get_view():visible() then
        if trust_job_name == self.detailsView:get_trust_job_name() then
            self.detailsView:set_visible(false)
        else
            self.detailsView:set_trust(trust, trust_job_name)
        end
    else
        self.detailsView:set_trust(trust, trust_job_name)
        self.detailsView:set_visible(true)
    end
end

return TrustHud
