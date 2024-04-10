---------------------------
-- Utility functions for zones.
-- @class module
-- @name zone_util

_libs = _libs or {}

require('lists')

local packets = require('packets')
local res = require('resources')

local zone_util = {}

_raw = _raw or {}

_libs.zone_util = zone_util

local cities = S{
    "Ru'Lude Gardens",
    "Upper Jeuno",
    "Lower Jeuno",
    "Port Jeuno",
    "Port Windurst",
    "Windurst Waters",
    "Windurst Woods",
    "Windurst Walls",
    "Heavens Tower",
    "Port San d'Oria",
    "Northern San d'Oria",
    "Southern San d'Oria",
    "Chateau d'Oraguille",
    "Port Bastok",
    "Bastok Markets",
    "Bastok Mines",
    "Metalworks",
    "Aht Urhgan Whitegate",
    "The Colosseum",
    "Tavnazian Safehold",
    "Nashmau",
    "Selbina",
    "Mhaura",
    "Rabao",
    "Norg",
    "Kazham",
    "Eastern Adoulin",
    "Western Adoulin",
    "Celennia Memorial Library",
    "Mog Garden",
    "Leafallia"
}

---
-- Checks if a given zone identifier corresponds to a city.
--
-- @param zone_id (string) The identifier of the zone to be checked.
-- @return (boolean) True if the zone is a city, false otherwise.
---
function zone_util.is_city(zone_id)
    return cities:contains(res.zones[zone_id].en)
end

function zone_util.zone(zone_id, zone_line, zone_type)
    if zone_id ~= windower.ffxi.get_info().zone or windower.ffxi.get_info().zone == 0 then
        return
    end
    local packet = packets.new('outgoing', 0x05E, {
        ['Zone Line'] = zone_line,
        ['Type'] = zone_type
    })
    packets.inject(packet)
end

function zone_util.is_valid_zone(zone_id)
    return zone_id ~= nil and res.zones[tonumber(zone_id)] ~= nil
end

function zone_util.is_valid_zone_request(zone_line, zone_type)
    return zone_line ~= nil and zone_type ~= nil and tonumber(zone_line) ~= 0
end

return zone_util