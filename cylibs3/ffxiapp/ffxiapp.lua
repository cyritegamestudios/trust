require('logger')
require('luau')

local table = require('table')
local https = require('cylibs/socket.http')
local ltn12 = require('cylibs/util/ltn12')
local config = require('config')
local json = require('cylibs/util/jsonencode')
local urlcode = require('cylibs/util/urlcode')
local mime = require('cylibs/util/mime')

local FFXIAppApi = {}
FFXIAppApi.__index = FFXIAppApi

function FFXIAppApi.new()
  local self = setmetatable({
    }, FFXIAppApi)
  return self
end

function FFXIAppApi:is_logged_in()
	return self.auth_token ~= nil
end

function FFXIAppApi:authenticate(username, password)
	local route = "https://ffxiapp.herokuapp.com/sign_in"
	
	local params = T{
		["username"] = username,
		["password"] = password,
	}
	
	response = self:send_api_post_request(route, params, false) 
	if response ~= nil then
		if response["error"] ~= nil then
			notice("Invalid username or password")
		else
			self.auth_token = response["auth_token"]
			notice("Successfully logged in to FFXIApp")
		end
	end
end

-- APIs

function FFXIAppApi:notify_incoming_tell(sender_name, message, player_id, thread_id)

	local route = "http://ffxiapp.herokuapp.com/incoming_tell"

	local params = T{
		["sender_name"] = sender_name,
		["message"] = message,
		["player_name"] = windower.ffxi.get_mob_by_id(player_id).name,
		["timestamp"] = os.time(),
		["thread_id"] = thread_id
	}

	self:send_api_post_request(route, params, true)
end

-- Helpers

function FFXIAppApi:send_api_post_request(route, params, is_authenticated)
	if is_authenticated then
		params["auth_token"] = self.auth_token
	end

	local payload = json.encode(params)
	
	local response_body = {}
	local res, code, response_headers, status = https.request {
		url = route,
    	method = "POST",
    	headers = {
			['Content-Type'] = 'application/json',
			['Content-Length'] = payload:len()
    	},
    	source = ltn12.source.string(payload),
		sink = ltn12.sink.table(response_body)
  	}

	response = json.decode(table.concat(response_body))
	
	return response
end

return FFXIAppApi









