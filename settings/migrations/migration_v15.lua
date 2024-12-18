---------------------------
-- Add nuke settings to Dark Knight.
-- @class module
-- @name Migration_v15

local Migration = require('settings/migrations/migration')
local Migration_v15 = setmetatable({}, { __index = Migration })
Migration_v15.__index = Migration_v15
Migration_v15.__class = "Migration_v15"

function Migration_v15.new()
    local self = setmetatable(Migration.new(), Migration_v15)
    return self
end

function Migration_v15:shouldPerform(trustSettings, _, _)
    return L{ 'DRK' }:contains(trustSettings.jobNameShort)
end

function Migration_v15:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.NukeSettings == nil then
            local defaultSettings = T(trustSettings:getDefaultSettings().Default.NukeSettings):clone()
            currentSettings.NukeSettings = defaultSettings
        end
    end
end

function Migration_v15:getDescription()
    return "Add nuke settings."
end

return Migration_v15




