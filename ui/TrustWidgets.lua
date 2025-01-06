local Frame = require('cylibs/ui/views/frame')
local WidgetManager = require('ui/widgets/WidgetManager')

local View = require('cylibs/ui/views/view')
local TrustWidgets = setmetatable({}, {__index = View })
TrustWidgets.__index = TrustWidgets


function TrustWidgets.new(addonSettings, actionQueue, addonEnabled, trust, mediaPlayer, soundTheme)
    local self = setmetatable(View.new(), TrustWidgets)

    self.addonSettings = addonSettings
    self.actionQueue = actionQueue
    self.addonEnabled = addonEnabled
    self.mediaPlayer = mediaPlayer
    self.soundTheme = soundTheme
    self.trust = trust
    self.widgetManager = WidgetManager.new(addonSettings)

    self:init()

    return self
end

function TrustWidgets:init()
    local TrustStatusWidget = require('ui/widgets/TrustStatusWidget')
    local trustStatusWidget = TrustStatusWidget.new(Frame.new(0, 0, 125, 69), self.addonSettings, self.addonEnabled, self.actionQueue, player.main_job_name, player.sub_job_name, self.trust:get_party():get_player(), function()
        --[[, self.mainMenuItem:getChildMenuItem("Profiles")]]
    end)
    self.widgetManager:addWidget(trustStatusWidget, "trust")

    local TargetWidget = require('ui/widgets/TargetWidget')
    local targetWidget = TargetWidget.new(Frame.new(0, 0, 125, 40), self.addonSettings, self.trust:get_party(), self.trust)
    self.widgetManager:addWidget(targetWidget, "target")

    local PartyStatusWidget = require('ui/widgets/PartyStatusWidget')
    local partyStatusWidget = PartyStatusWidget.new(Frame.new(0, 0, 125, 55), self.addonSettings, self.trust:get_alliance(), self.trust:get_party(), self.trust, self.mediaPlayer, self.soundTheme)
    self.widgetManager:addWidget(partyStatusWidget, "party")

    local PathWidget = require('ui/widgets/PathWidget')
    local pathWidget = PathWidget.new(Frame.new(0, 0, 125, 57), self.addonSettings, self.trust:get_party():get_player(), self.trust)
    self.widgetManager:addWidget(pathWidget, "path")

    for widget in self.widgetManager:getAllWidgets():it() do
        self:addSubview(widget)
    end

    -- Job specific
    for trust in L{ self.trust }:it() do
        coroutine.schedule(function()
            local widget, widgetName = trust:get_widget()
            if widget and widgetName then
                self:addWidget(widget, widgetName)
            end
        end, 0.5)
    end
end

function TrustWidgets:addWidget(widget, widgetName)
    self.widgetManager:addWidget(widget, widgetName)
    self:addSubview(widget)
end

function TrustWidgets:getWidget(widgetName)
    return self.widgetManager:getWidget(widgetName)
end

function TrustWidgets:hitTest(x, y)
    for widget in self.widgetManager:getAllWidgets():it() do
        if widget:hitTest(x, y) then
            return true
        end
    end
    return false
end

return TrustWidgets