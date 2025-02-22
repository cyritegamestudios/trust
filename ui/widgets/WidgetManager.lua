local DisposeBag = require('cylibs/events/dispose_bag')

local WidgetManager = {}
WidgetManager.__index = WidgetManager
WidgetManager.__class = "WidgetManager"

function WidgetManager.new()
    local self = setmetatable({}, WidgetManager)

    self.widgets = {}
    self.disposeBag = DisposeBag.new()

    return self
end

function WidgetManager:destroy()
    self.disposeBag:destroy()
end

function WidgetManager:addWidget(widget, widgetName)
    if self:getWidget(widgetName) then
        return
    end
    widget.widgetName = widgetName
    widget:createSettings()

    local settings = widget:getSettings()

    local xPos = settings.x
    local yPos = settings.y

    logger.notice(self.__class, 'addWidget', 'widgetName', xPos, yPos)

    self.widgets[widgetName] = widget

    widget:setPosition(xPos, yPos)
    widget:setVisible(true)

    widget:layoutIfNeeded()

    self.disposeBag:add(widget:onSettingsChanged():addAction(function(w)
        settings.x = w:getPosition().x
        settings.y = w:getPosition().y
        settings:save()

        addon_system_message("Widget settings saved.")
    end), widget:onSettingsChanged())

    self.disposeBag:addAny(L{ widget })
end

function WidgetManager:removeWidget(widgetName)
    local widget = self:getWidget(widgetName)
    if not widget then
        return
    end
    widget:destroy()
end

function WidgetManager:getWidget(widgetName)
    return self.widgets[widgetName] or self.widgets[widgetName:lower()]
end

function WidgetManager:getAllWidgets()
    local widgets = L{}
    for _, widget in pairs(self.widgets) do
        widgets:append(widget)
    end
    return widgets
end

return WidgetManager