---------------------------
-- Adds Entrust spell to Geomancy settings.
-- @class module
-- @name Migration_v19

local Migration = require('settings/migrations/migration')
local Migration_v19 = setmetatable({}, { __index = Migration })
Migration_v19.__index = Migration_v19
Migration_v19.__class = "Migration_v19"

function Migration_v19.new()
    local self = setmetatable(Migration.new(), Migration_v19)
    return self
end

function Migration_v19:shouldPerform(trustSettings, _, _)
    return L{ 'GEO' }:contains(trustSettings.jobNameShort)
end

function Migration_v19:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        if trustSettings:getSettings()[modeName].Geomancy == nil then
            trustSettings:getSettings()[modeName].Geomancy = defaultSettings.Geomancy
        else
            trustSettings:getSettings()[modeName].Geomancy.Entrust = defaultSettings.Geomancy.Entrust
        end
    end
end

function Migration_v19:getDescription()
    return "Adding entrust to geomancy settings."
end

return Migration_v19




