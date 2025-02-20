local DisposeBag = require('cylibs/events/dispose_bag')

local WidgetManager = {}
WidgetManager.__index = WidgetManager
WidgetManager.__class = "WidgetManager"

function WidgetManager.new()
    local self = setmetatable({}, WidgetManager)

    self.widgets = {}
    self.widgetsToSave = S{}
    self.disposeBag = DisposeBag.new()

    return self
end

function WidgetManager:destroy()
    self.disposeBag:destroy()
end

function WidgetManager:onInit()
end

function WidgetManager:addWidget(widget, widgetName)
    if self:getWidget(widgetName) then
        return
    end
    widget.widgetName = widgetName

    local settings = Widget:get({ name = widgetName, user_id = windower.ffxi.get_player().id })

    local xPos = settings and settings.x or widget:getDefaultPosition().x
    local yPos = settings and settings.y or widget:getDefaultPosition().y

    logger.notice(self.__class, 'addWidget', 'widgetName', xPos, yPos)

    self.widgets[widgetName] = widget

    widget:setPosition(xPos, yPos)
    widget:setVisible(true)
    widget:layoutIfNeeded()

    self.disposeBag:add(widget:onSettingsChanged():addAction(function(w)
        local widget = Widget({
            name = w.widgetName,
            x = w:getPosition().x,
            y = w:getPosition().y,
            user_id = windower.ffxi.get_player().id
        })
        widget:save()

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