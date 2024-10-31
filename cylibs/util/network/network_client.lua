local Event = require('cylibs/events/Luvent')

local NetworkClient = {}
NetworkClient.__index = NetworkClient

function NetworkClient:onPrerender()
    return self.prerender
end

function NetworkClient.new()
    local self = setmetatable({}, NetworkClient)

    self.events = {}
    self.prerender = Event.newEvent()

    return self
end

function NetworkClient:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self:onPrerender():removeAllActions()
end

function NetworkClient.shared()
    if shared_client == nil then
        shared_client = NetworkClient.new()
    end
    return shared_client
end

return NetworkClient