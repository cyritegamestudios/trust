local Event = require('cylibs/events/Luvent')

local Render = {}
Render.__index = Render

function Render:onPrerender()
    return self.prerender
end

function Render.new()
    local self = setmetatable({}, Render)

    self.events = {}
    self.prerender = Event.newEvent()

    self.events.prerender = windower.register_event('prerender', function()
        self:onPrerender():trigger()
    end)

    return self
end

function Render:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self:onPrerender():removeAllActions()
end

function Render.shared()
    if renderer == nil then
        renderer = Render.new()
    end
    return renderer
end

return Render