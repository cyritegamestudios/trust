local DisposeBag = require('cylibs/events/dispose_bag')

local WidgetManager = {}
WidgetManager.__index = WidgetManager
WidgetManager.__class = "WidgetManager"

function WidgetManager.new(addonSettings)
    local self = setmetatable({}, WidgetManager)

    self.addonSettings = addonSettings
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

    local settings = widget:getSettings(self.addonSettings)
    if settings.visible then
        logger.notice(self.__class, 'addWidget', 'widgetName', settings.x, settings.y)

        self.widgets[widgetName] = widget

        widget:setPosition(settings.x, settings.y)
        widget:setVisible(true)
        widget:layoutIfNeeded()

        self.disposeBag:add(widget:onSettingsChanged():addAction(function(w)
            if not self.widgetsToSave:contains(widget) then
                logger.notice(self.__class, 'onSettingsChanged', w.title)
                self.widgetsToSave:add(w)
            end
        end), widget:onSettingsChanged())

        self.disposeBag:addAny(L{ widget })
    else
        logger.notice(self.__class, 'addWidget', 'hide')
        widget:destroy()
    end
end

function WidgetManager:getWidget(widgetName)
    return self.widgets[widgetName]
end

function WidgetManager:saveChanges()
    if not self.widgetsToSave:empty() then
        logger.notice(self.__class, 'saveChanges', 'saving batched changes', self.widgetsToSave:map(function(w) return w.title end))

        for widget in self.widgetsToSave:it() do
            local settings = widget:getSettings(self.addonSettings)
            if settings then
                settings.x = widget:getPosition().x
                settings.y = widget:getPosition().y
            end
        end
        self.widgetsToSave:clear()

        self.addonSettings:saveSettings(true)
    end
end

return WidgetManager