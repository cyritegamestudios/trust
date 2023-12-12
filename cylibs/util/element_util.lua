

_libs = _libs or {}

local element_util = {}

_raw = _raw or {}

_libs.element_util = element_util

local Element = {}
Element.__index = Element

function Element.new(name)
    local self = setmetatable({
        name = name,
    }, Element)

    return self
end

function Element.equals(obj1, obj2)
    return obj1.name == obj2.name
end

Element.__eq = Element.equals

element_util.Light = Element.new("Light")
element_util.Fire = Element.new("Fire")
element_util.Thunder = Element.new("Thunder")
element_util.Wind = Element.new("Wind")
element_util.Dark = Element.new("Dark")
element_util.Earth = Element.new("Earth")
element_util.Water = Element.new("Water")
element_util.Ice = Element.new("Ice")

element_util.Light.weak_to = element_util.Dark
element_util.Light.strong_to = element_util.Dark

element_util.Fire.weak_to = element_util.Water
element_util.Fire.strong_to = element_util.Ice

element_util.Thunder.weak_to = element_util.Earth
element_util.Thunder.strong_to = element_util.Water

element_util.Wind.weak_to = element_util.Ice
element_util.Wind.strong_to = element_util.Earth

element_util.Dark.weak_to = element_util.Light
element_util.Dark.strong_to = element_util.Light

element_util.Earth.weak_to = element_util.Wind
element_util.Earth.strong_to = element_util.Thunder

element_util.Water.weak_to = element_util.Thunder
element_util.Water.strong_to = element_util.Fire

element_util.Ice.weak_to = element_util.Fire
element_util.Ice.strong_to = element_util.Wind



return element_util
