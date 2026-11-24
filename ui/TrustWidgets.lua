local WidgetManager = require('ui/widgets/WidgetManager')

local View = require('cylibs/ui/views/view')
local TrustWidgets = setmetatable({}, {__index = View })
TrustWidgets.__index = TrustWidgets


function TrustWidgets.new(actionQueue, addonEnabled, trust, mediaPlayer, soundTheme)
    local self = setmetatable(View.new(), TrustWidgets)

    self.actionQueue = actionQueue
    self.addonEnabled = addonEnabled
    self.mediaPlayer = mediaPlayer
    self.soundTheme = soundTheme
    self.trust = trust
    self.widgetManager = WidgetManager.new()

    self:init()

    return self
end

function TrustWidgets:init()
    -- Widgets removed at the user's request (2026-11-15).
    -- The three status widgets (Trust, Target, Party) and the
    -- job widget (e.g. the Bard song display) are no longer
    -- created, so nothing is drawn on screen. Trust itself,
    -- its menu (Ctrl+Numpad+) and its commands are unaffected.
    -- To bring the widgets back, restore the original
    -- TrustWidgets.lua and //lua reload trust.
end

function TrustWidgets:addWidget(widget, widgetName)
    self.widgetManager:addWidget(widget, widgetName)
    self:addSubview(widget)
end

function TrustWidgets:getWidget(widgetName)
    return self.widgetManager:getWidget(widgetName)
end

function TrustWidgets:removeWidget(widgetName)
    self.widgetManager:removeWidget(widgetName)
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