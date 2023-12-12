local Event = require('cylibs/events/Luvent')
local Frame = require('cylibs/ui/views/frame')

local ViewStack = {}
ViewStack.__index = ViewStack

function ViewStack:onKeyboardEvent()
    return self.keyboardEvent
end

function ViewStack:onViewDismissed()
    return self.viewDismissed
end

function ViewStack:onStackSizeChanged()
    return self.stackSizeChanged
end

function ViewStack:onEmpty()
    return self.empty
end

function ViewStack.new(startPosition)
    local self = setmetatable({}, ViewStack)

    self.currentView = nil
    self.events = {}
    self.stack = L{}
    self.startPosition = startPosition
    self.keyboardEvent = Event.newEvent()
    self.viewDismissed = Event.newEvent()
    self.stackSizeChanged = Event.newEvent()
    self.empty = Event.newEvent()
    self.name = os.time()

    self.events.keyboard = windower.register_event('keyboard', function(key, pressed, flags, blocked)
        if blocked or self.currentView == nil or not self:hasFocus() then
            self:onKeyboardEvent():trigger(self, key, pressed, flags, true)
            return false
        end
        if pressed then
            -- escape, left, right
            if L{1, 203, 205}:contains(key) then
                self:onKeyboardEvent():trigger(self, key, pressed, flags, blocked)
                return true
            end
            if self.currentView and type(self.currentView.onKeyboardEvent) == 'function' then
                return self.currentView:onKeyboardEvent(key, pressed, flags, blocked)
            end
        end
        return false
    end)

    self:focus()

    return self
end

function ViewStack:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self.viewDismissed:removeAllActions()
    self.stackSizeChanged:removeAllActions()
    self.keyboardEvent:removeAllActions()
    self.empty:removeAllActions()
end

function ViewStack:present(view)
    self.stack:append(view)

    self:onStackSizeChanged():trigger(self:getNumViews())

    if self.currentView then
        self.currentView:setVisible(false)
        self.currentView:layoutIfNeeded()
    end

    self.currentView = view
    if self.startPosition then
        self.currentView:setPosition(self.startPosition.x, self.startPosition.y)
    else
        self.currentView:setPosition((windower.get_windower_settings().ui_x_res - view:getSize().width) / 2, (windower.get_windower_settings().ui_y_res - view:getSize().height) / 2)
    end

    if self.currentView:shouldRequestFocus() then
        self:focus()
        self.currentView:setHasFocus(true)
    end
    self.currentView:setVisible(true)
    self.currentView:layoutIfNeeded()
end

function ViewStack:dismiss()
    local oldView = self.currentView
    if self.currentView then
        self.stack:remove(self.stack:length())

        self.currentView:destroy()
        self.currentView = nil
    end

    if self:getNumViews() > 0 then
        self.currentView = self.stack[self.stack:length()]
        self.currentView:setVisible(true)
        self.currentView:layoutIfNeeded()
    else
        self:onEmpty():trigger(self)
    end
    self:onViewDismissed():trigger(self, oldView)
end

function ViewStack:dismissAll()
    while self.stack:length() > 0 do
        self:dismiss()
    end
end

function ViewStack:hasFocus()
    return activeStack == self
end

function ViewStack:focus()
    if activeStack and activeStack ~= self then
        if activeStack:getCurrentView() then
            activeStack:getCurrentView():setHasFocus(false)
        end
    end
    activeStack = self
    if self.currentView then
        self.currentView:setHasFocus(true)
    end
end

function ViewStack:blockInput()

end

function ViewStack:enableInput()

end

function ViewStack:getCurrentView()
    return self.currentView
end

function ViewStack:getNumViews()
    return self.stack:length()
end

function ViewStack:isEmpty()
    return self:getNumViews() == 0
end

return ViewStack