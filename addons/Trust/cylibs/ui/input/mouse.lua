local Event = require('cylibs/events/Luvent')

local Mouse = {}
Mouse.__index = Mouse

function Mouse:onMove()
    return self.move
end

function Mouse:onClick()
    return self.click
end

function Mouse:onClickRelease()
    return self.clickRelease
end

function Mouse:onMouseEvent()
    return self.mouseEvent
end

function Mouse.new()
    local self = setmetatable({}, Mouse)

    self.events = {}
    self.move = Event.newEvent()
    self.click = Event.newEvent()
    self.clickRelease = Event.newEvent()
    self.mouseEvent = Event.newEvent()

    self.events.mouse = windower.register_event('mouse', function(type, x, y, delta, blocked)
        if type == Mouse.Event.Move then
            self:onMove():trigger(type, x, y, delta, blocked)
        elseif type == Mouse.Event.Click then
            self:onClick():trigger(type, x, y, delta, blocked)
        elseif type == Mouse.Event.ClickRelease then
            self:onClickRelease():trigger(type, x, y, delta, blocked)
        end
        self:onMouseEvent():trigger(type, x, y, delta, blocked)
        return false
    end)

    return self
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
    self:onMouseEvent():removeAllActions()
end

function Mouse.input()
    if mouse_input == nil then
        mouse_input = Mouse.new()
    end
    return mouse_input
end

Mouse.Event = {}
Mouse.Event.Move = 0
Mouse.Event.Click = 1
Mouse.Event.ClickRelease = 2

return Mouse