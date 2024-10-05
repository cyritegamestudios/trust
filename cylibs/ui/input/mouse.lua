local Event = require('cylibs/events/Luvent')

local Mouse = {}
Mouse.__index = Mouse

Mouse.Event = {}
Mouse.Event.Move = 0
Mouse.Event.Click = 1
Mouse.Event.ClickRelease = 2
Mouse.Event.Wheel = 10

function Mouse:onMove()
    return self.move
end

function Mouse:onClick()
    return self.click
end

function Mouse:onClickRelease()
    return self.clickRelease
end

function Mouse:onMouseWheel()
    return self.mouseWheel
end

function Mouse:onMouseEvent()
    return self.mouseEvent
end

function Mouse.new()
    local self = setmetatable({}, Mouse)

    self.rootView = hud
    self.events = {}
    self.move = Event.newEvent()
    self.click = Event.newEvent()
    self.clickRelease = Event.newEvent()
    self.mouseWheel = Event.newEvent()
    self.mouseEvent = Event.newEvent()
    self.blockEvent = false
    self.mouseEventCooldown = 0.0
    self.lastMouseEvent = {}

    self.events.mouse = windower.register_event('mouse', function(type, x, y, delta, blocked)
        local lastTime = self.lastMouseEvent[type] or 0
        if os.time() - lastTime < self:getCooldown(type) then
            return
        end
        self.lastMouseEvent[type] = os.time()

        return self:handleMouseEvent(type, x, y, delta)
    end)

    return self
end

function Mouse:handleMouseEvent(type, x, y, delta)
    local handled
    local currentView
    local allViews = Q{ hud }
    if hud.trustMenu.menuView then
        allViews:push(hud.trustMenu.menuView)
    end
    if hud.viewStack.currentView then
        allViews:push(hud.viewStack.currentView)
    end
    while not allViews:empty() do
        currentView = allViews:pop()
        if currentView:hitTest(x, y) then
            handled = currentView:onMouseEvent(type, x, y, delta)
            if handled then
                return true
            else
                for subview in currentView:getSubviews():it() do
                    if subview:isUserInteractionEnabled() then
                        allViews:push(subview)
                    end
                end
            end
        end
    end
    return false
end

function Mouse:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self:onMove():removeAllActions()
    self:onClick():removeAllActions()
    self:onClickRelease():removeAllActions()
    self:onMouseWheel():removeAllActions()
    self:onMouseEvent():removeAllActions()
end

function Mouse.input()
    if mouse_input == nil then
        mouse_input = Mouse.new()
    end
    return mouse_input
end



function Mouse:setMouseEventCooldown(mouseEventCooldown)
    self.mouseEventCooldown = mouseEventCooldown
end

function Mouse:getCooldown(mouseEvent)
    if L{ Mouse.Event.Click, Mouse.Event.ClickRelease }:contains(mouseEvent) then
        return self.mouseEventCooldown
    end
    return 0.0
end

return Mouse