--[[
This library provides a set of functions to log analytics.
]]

_libs = _libs or {}

local config = require('config')
local amplitude = require('cylibs/analytics/amplitude')

local analytics = {}

_raw = _raw or {}

-- Set up, based on addon.
analytics.defaults = {}
analytics.settings = config.load(analytics.defaults)

_libs.analytics = analytics

function analytics.log_event(event_type, event_properties)
	amplitude.log_event(event_type, event_properties)
end

return analytics