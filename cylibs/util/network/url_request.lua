local http = require('socket.http')
local https = require('ssl.https')
local ltn12 = require('ltn12')
local Event = require('cylibs/events/Luvent')
local JSON = require('cylibs/util/jsonencode')

local UrlRequest = {}
UrlRequest.__index = UrlRequest

function UrlRequest.new(method, url, data)
    local self = setmetatable({}, UrlRequest)

    self.method = method
    self.url = url
    self.data = data
    self.timeout = 0.075
    self.events = {}
    self.prerender = Event.newEvent()

    return self
end

function UrlRequest:destroy()
    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
    self:onPrerender():removeAllActions()
end

function UrlRequest:get()
    https.TIMEOUT = self.timeout

    self.coroutine = coroutine.create(function()
        local body = {}

        local response, code, headers, status = https.request {
            url=self.url, method='GET',
            sink=ltn12.sink.table(body),
        }
        if code == 200 then
            body = JSON.decode(table.concat(body))
        end
        coroutine.yield(response, code, body, status)
    end)
    return self.coroutine
end

function UrlRequest:post()
    https.TIMEOUT = self.timeout

    self.coroutine = coroutine.create(function()
        local data = JSON.encode(self.data)
        local body = {}

        local response, code, headers, status = http.request {
            url=self.url, method='POST',
            protocol='any',
            headers={
                ["Content-Type"]="application/json",
                ["Content-Length"]=#data
            },
            source=ltn12.source.string(data),
            sink=ltn12.sink.table(body)

        }
        coroutine.yield(response, code, JSON.decode(table.concat(body)), status)
    end)
    return self.coroutine
end

return UrlRequest