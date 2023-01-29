--[[
This library provides a set of functions to send a GET and POST request.
]]

_libs = _libs or {}

require('logger')

local table = require('table')
local https = require('cylibs/socket/http')
local ltn12 = require('cylibs/util/ltn12')
local config = require('config')
local json = require('cylibs/util/jsonencode')
local urlcode = require('cylibs/util/urlcode')
local mime = require('cylibs/util/mime')

local urlrequest = {}

_raw = _raw or {}

verbose = false

_libs.urlrequest = urlrequest

function urlrequest.get(url)
    local player = windower.ffxi.get_player()
    if player ~= nil then
        local  res, code, headers, status =
        https.request {
            url = "%s":format(url),
			method = "GET",
		}
	
    if verbose then
        notice('[Request] Status: ' .. status .. ' Code: ' .. code)
    end
    end
end

function urlrequest.build_params(user_id, params)
    return urlrequest.encode_params({params=params, user_id=user_id})
end

function urlrequest.encode_params(params)
    local jsonstring = json.encode(params)
    if jsonstring then
        jsonstring = urlcode.escape(jsonstring)
    end
    return jsonstring
end

function urlrequest.encode_str(str)
    str = urlcode.escape(str)
    return str
end

return urlrequest