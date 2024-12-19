---------------------------
-- Add nuke settings to Blue Mage.
-- @class module
-- @name Migration_v16

local Migration = require('settings/migrations/migration')
local Migration_v16 = setmetatable({}, { __index = Migration })
Migration_v16.__index = Migration_v16
Migration_v16.__class = "Migration_v16"

function Migration_v16.new()
    local self = setmetatable(Migration.new(), Migration_v16)
    return self
end

function Migration_v16:shouldPerform(trustSettings, _, _)
    return L{ 'BLU' }:contains(trustSettings.jobNameShort)
end

function Migration_v16:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.NukeSettings == nil then
            local defaultSettings = T(trustSettings:getDefaultSettings().Default.NukeSettings):clone()
            currentSettings.NukeSettings = defaultSettings
        end
    end
end

function Migration_v16:getDescription()
    return "Add nuke settings."
end

return Migration_v16




