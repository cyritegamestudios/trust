--[[
This library provides a set of functions to send a GET and POST request.
]]

_libs = _libs or {}

require('logger')

local urlrequest = require('cylibs/networking/urlrequest')
local urlcode = require('cylibs/util/urlcode')

local discord_client = {}

_raw = _raw or {}

verbose = false

_libs.discord_client = discord_client

function discord_client.send_message(message)
    url = 'https://ffxi-app.herokuapp.com/cyrite_bot/message?message=%s':format(discord_client.encode_str(message))
    coroutine.schedule(function()
        urlrequest.get(url)
    end, 0.5)
end

function discord_client.forward_tell(message)
    url = 'https://ffxi-app.herokuapp.com/cyrite_bot/tell_forwarding?message=%s':format(discord_client.encode_str(message))
    windower.open_url(url)
    --coroutine.schedule(function()
    --    urlrequest.get(url)
    --end, 0.5)
end

function discord_client.encode_str(str)
    str = urlcode.escape(str)
    return str
end


return discord_client