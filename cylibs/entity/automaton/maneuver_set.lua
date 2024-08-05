---------------------------
-- Represents a maneuver set.
-- @class module
-- @name ManeuverSet
local serializer_util = require('cylibs/util/serializer_util')

local ManeuverSet = {}
ManeuverSet.__index = ManeuverSet
ManeuverSet.__type = "ManeuverSet"
ManeuverSet.__class = "ManeuverSet"

function ManeuverSet.new(fire_maneuvers, earth_maneuvers, water_maneuvers, wind_maneuvers, ice_maneuvers, thunder_maneuvers, light_maneuvers, dark_maneuvers)
    local self = setmetatable({}, ManeuverSet)
    self.maneuvers = T{
        Fire = fire_maneuvers or 1,
        Earth = earth_maneuvers or 1,
        Water = water_maneuvers or 1,
        Wind = wind_maneuvers or 0,
        Ice = ice_maneuvers or 0,
        Thunder = thunder_maneuvers or 0,
        Light = light_maneuvers or 0,
        Dark = dark_maneuvers or 0
    }
    return self
end

function ManeuverSet:getNumManeuvers(element_name)
    return self.maneuvers[element_name] or 0
end

function ManeuverSet:getTotalNumManeuvers()
    local count = 0
    for _, numManeuvers in pairs(self.maneuvers) do
        count = count + numManeuvers
    end
    return count
end

function ManeuverSet:tostring()
    local maneuvers = L{}
    for elementName, numManeuvers in pairs(self.maneuvers) do
        if numManeuvers > 0 then
            maneuvers:append(elementName.." Maneuver ("..numManeuvers..")")
        end
    end
    return localization_util.commas(maneuvers)
end

function ManeuverSet:serialize()
    return "ManeuverSet.new(" .. serializer_util.serialize_args(self.maneuvers.Fire, self.maneuvers.Earth, self.maneuvers.Water, self.maneuvers.Wind, self.maneuvers.Ice, self.maneuvers.Thunder, self.maneuvers.Light, self.maneuvers.Dark) .. ")"
end

return ManeuverSet




