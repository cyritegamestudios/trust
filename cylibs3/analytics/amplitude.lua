--[[
This library provides a set of functions to log to amplitude.
]]

_libs = _libs or {}

require('logger')

local table = require('table')
local https = require('cylibs/socket.http')
local ltn12 = require('cylibs/util/ltn12')
local config = require('config')
local json = require('cylibs/util/jsonencode')
local urlcode = require('cylibs/util/urlcode')
local mime = require('cylibs/util/mime')

local amplitude = {}

_raw = _raw or {}

apikey = "6a2bf9d282d4b3280be19deda017ae76"
verbose = false

_libs.amplitude = amplitude

function amplitude.log_event(event_type, event_properties)
	local player = windower.ffxi.get_player()
	if player ~= nil then
		local data = amplitude.build_params(player.id, event_type, event_properties)

		local  res, code, headers, status =
		https.request {
			url = "http://api.amplitude.com/httpapi?api_key=%s&event=%s":format(apikey, data),
			method = "GET",
		}
		if verbose then
			notice('[Amplitude] Status: ' .. status .. ' Code: ' .. code)
		end
	end
end

function amplitude.build_params(user_id, event_type, event_properties)
	return amplitude.encode_params({event_type=event_type, user_id=user_id, event_properties=event_properties})
end

function amplitude.encode_params(params)
	local jsonstring = json.encode(params)
	if jsonstring then
		jsonstring = urlcode.escape(jsonstring)
	end
	return jsonstring
end


return amplitude