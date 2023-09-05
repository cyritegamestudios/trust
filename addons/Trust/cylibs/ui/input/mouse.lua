local Event = require('cylibs/events/Luvent')

local Mouse = {}
Mouse.__index = Mouse

function Mouse:onMove()
    return self.move
end

function Mouse:onClick()
    return self.click
end

function Mouse.new()
    local self = setmetatable({}, Mouse)

    self.events = {}
    self.move = Event.newEvent()
    self.click = Event.newEvent()

    self.events.mouse = windower.register_event('mouse', function(type, x, y, delta, blocked)
        if type == 0 then
            self:onMove():trigger(type, x, y, delta, blocked)
        elseif type == 1 then
            self:onClick():trigger(type, x, y, delta, blocked)
        end
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
end

return Mouse