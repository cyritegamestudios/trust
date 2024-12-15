---------------------------
-- Adds GearSwapSettings to all job settings files.
-- @class module
-- @name Migration_v14

local Migration = require('settings/migrations/migration')
local Migration_v14 = setmetatable({}, { __index = Migration })
Migration_v14.__index = Migration_v14
Migration_v14.__class = "Migration_v14"

function Migration_v14.new()
    local self = setmetatable(Migration.new(), Migration_v14)
    return self
end

function Migration_v14:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.GearSwapSettings == nil
end

function Migration_v14:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].GearSwapSettings = defaultSettings.GearSwapSettings
    end
end

function Migration_v14:getDescription()
    return "Adding gear swap settings."
end

return Migration_v14




