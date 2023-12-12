

require('sets')
local element_util = require('cylibs/util/element_util')

_libs = _libs or {}

local skillchain_util = {}

_raw = _raw or {}

_libs.skillchain_util = skillchain_util

local Skillchain = {}
Skillchain.__index = Skillchain

function Skillchain.new(elements, level)
    local self = setmetatable({
        elements = elements,
        level = level,
    }, Skillchain)

    return self
end

function Skillchain.equals(obj1, obj2)
    return obj1.elements == obj2.elements and obj1.level == obj2.level
end

Skillchain.__eq = Skillchain.equals


skillchain_util.Transfixion = Skillchain.new(S{element_util.Light}, 1)
skillchain_util.Liquefaction = Skillchain.new(S{element_util.Fire}, 1)
skillchain_util.Impaction = Skillchain.new(S{element_util.Thunder}, 1)
skillchain_util.Detonation = Skillchain.new(S{element_util.Wind}, 1)
skillchain_util.Compression = Skillchain.new(S{element_util.Dark}, 1)
skillchain_util.Reverberation = Skillchain.new(S{element_util.Water}, 1)
skillchain_util.Scission = Skillchain.new(S{element_util.Earth}, 1)
skillchain_util.Induration = Skillchain.new(S{element_util.Ice}, 1)

skillchain_util.Fusion = Skillchain.new(S{element_util.Light,element_util.Fire}, 2)
skillchain_util.Fragmentation = Skillchain.new(S{element_util.Thunder,element_util.Wind}, 2)
skillchain_util.Gravitation = Skillchain.new(S{element_util.Dark,element_util.Earth}, 2)
skillchain_util.Distortion = Skillchain.new(S{element_util.Water,element_util.Ice}, 2)

skillchain_util.Light = Skillchain.new(S{element_util.Light,element_util.Fire,element_util.Thunder,element_util.Wind}, 3)
skillchain_util.Darkness = Skillchain.new(S{element_util.Dark,element_util.Water,element_util.Earth,element_util.Ice}, 3)

skillchain_util.LightLv4 = Skillchain.new(S{element_util.Light,element_util.Fire,element_util.Thunder,element_util.Wind}, 4)
skillchain_util.DarknessLv4 = Skillchain.new(S{element_util.Dark,element_util.Water,element_util.Earth,element_util.Ice}, 4)

skillchain_util.Radiance = Skillchain.new(S{element_util.Light,element_util.Fire,element_util.Thunder,element_util.Wind}, 4)
skillchain_util.Umbra = Skillchain.new(S{element_util.Dark,element_util.Water,element_util.Earth,element_util.Ice}, 4)

skillchain_util.Transfixion.Compression = skillchain_util.Compression
skillchain_util.Transfixion.Scission = skillchain_util.Distortion
skillchain_util.Transfixion.Reverberation = skillchain_util.Reverberation

skillchain_util.Liquefaction.Scission = skillchain_util.Scission
skillchain_util.Liquefaction.Impaction = skillchain_util.Fusion

skillchain_util.Impaction.Liquefaction = skillchain_util.Liquefaction
skillchain_util.Impaction.Detonation = skillchain_util.Detonation

skillchain_util.Detonation.Compression = skillchain_util.Gravitation
skillchain_util.Detonation.Scission = skillchain_util.Scission

skillchain_util.Compression.Transfixion = skillchain_util.Transfixion
skillchain_util.Compression.Detonation = skillchain_util.Detonation

skillchain_util.Reverberation.Induration = skillchain_util.Induration
skillchain_util.Reverberation.Impaction = skillchain_util.Impaction

skillchain_util.Scission.Liquefaction = skillchain_util.Liquefaction
skillchain_util.Scission.Reverberation = skillchain_util.Reverberation
skillchain_util.Scission.Detonation = skillchain_util.Detonation

skillchain_util.Induration.Compression = skillchain_util.Compression
skillchain_util.Induration.Reverberation = skillchain_util.Fragmentation
skillchain_util.Induration.Impaction = skillchain_util.Impaction

skillchain_util.Fusion.Gravitation = skillchain_util.Gravitation
skillchain_util.Fusion.Fragmentation = skillchain_util.Light

skillchain_util.Fragmentation.Distortion = skillchain_util.Distortion
skillchain_util.Fragmentation.Fusion = skillchain_util.Light

skillchain_util.Gravitation.Distortion = skillchain_util.Darkness
skillchain_util.Gravitation.Fragmentation = skillchain_util.Fragmentation

skillchain_util.Distortion.Gravitation = skillchain_util.Darkness
skillchain_util.Distortion.Fusion = skillchain_util.Fusion

skillchain_util.Light.Light = skillchain_util.LightLv4
skillchain_util.Darkness.Darkness = skillchain_util.DarknessLv4

skillchain_util.Light.Radiance = skillchain_util.Radiance
skillchain_util.Darkness.Umbra = skillchain_util.Umbra

-- Chainbound
skillchain_util.Chainbound = Skillchain.new(nil, 0)
skillchain_util.Chainbound.Transfixion = skillchain_util.Transfixion
skillchain_util.Chainbound.Liquefaction = skillchain_util.Liquefaction
skillchain_util.Chainbound.Impaction = skillchain_util.Impaction
skillchain_util.Chainbound.Detonation = skillchain_util.Detonation
skillchain_util.Chainbound.Compression = skillchain_util.Compression
skillchain_util.Chainbound.Reverberation = skillchain_util.Reverberation
skillchain_util.Chainbound.Scission = skillchain_util.Scission
skillchain_util.Chainbound.Induration = skillchain_util.Induration

skillchain_util.Chainbound.Fusion = skillchain_util.Fusion
skillchain_util.Chainbound.Fragmentation = skillchain_util.Fragmentation
skillchain_util.Chainbound.Gravitation = skillchain_util.Gravitation
skillchain_util.Chainbound.Distortion = skillchain_util.Distortion

skillchain_util.Chainbound.Light = skillchain_util.Light
skillchain_util.Chainbound.Darkness = skillchain_util.Darkness

skillchain_util.colors = {}            -- Color codes by Sammeh
skillchain_util.colors.Light =         '\\cs(255,255,255)'
skillchain_util.colors.Dark =          '\\cs(0,0,204)'
skillchain_util.colors.Ice =           '\\cs(0,255,255)'
skillchain_util.colors.Water =         '\\cs(0,0,255)'
skillchain_util.colors.Earth =         '\\cs(153,76,0)'
skillchain_util.colors.Wind =          '\\cs(102,255,102)'
skillchain_util.colors.Fire =          '\\cs(255,0,0)'
skillchain_util.colors.Lightning =     '\\cs(255,0,255)'
skillchain_util.colors.Gravitation =   '\\cs(102,51,0)'
skillchain_util.colors.Fragmentation = '\\cs(250,156,247)'
skillchain_util.colors.Fusion =        '\\cs(255,102,102)'
skillchain_util.colors.Distortion =    '\\cs(51,153,255)'
skillchain_util.colors.Darkness =      skillchain_util.colors.Dark
skillchain_util.colors.Umbra =         skillchain_util.colors.Dark
skillchain_util.colors.Compression =   skillchain_util.colors.Dark
skillchain_util.colors.Radiance =      skillchain_util.colors.Light
skillchain_util.colors.Transfixion =   skillchain_util.colors.Light
skillchain_util.colors.Induration =    skillchain_util.colors.Ice
skillchain_util.colors.Reverberation = skillchain_util.colors.Water
skillchain_util.colors.Scission =      skillchain_util.colors.Earth
skillchain_util.colors.Detonation =    skillchain_util.colors.Wind
skillchain_util.colors.Liquefaction =  skillchain_util.colors.Fire
skillchain_util.colors.Impaction =     skillchain_util.colors.Lightning

function skillchain_util.color_for_element(element_name)
    return skillchain_util.colors[element_name] or skillchain_util.colors[(element_name:gsub("^%l", string.upper))]
end


return skillchain_util
