---------------------------
-- Adding JobAbilities key to NukeSettings.
-- @class module
-- @name Migration_v7

local Migration = require('settings/migrations/migration')
local Migration_v7 = setmetatable({}, { __index = Migration })
Migration_v7.__index = Migration_v7
Migration_v7.__class = "Migration_v7"

function Migration_v7.new()
    local self = setmetatable(Migration.new(), Migration_v7)
    return self
end

function Migration_v7:shouldPerform(trustSettings, _, _)
    local defaultSettings = trustSettings:getDefaultSettings()
    return defaultSettings.Default.NukeSettings ~= nil
end

function Migration_v7:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.NukeSettings then
            if currentSettings.NukeSettings.JobAbilities == nil then
                local defaultSettings = T(trustSettings:getDefaultSettings().Default.NukeSettings):clone()
                currentSettings.NukeSettings.JobAbilities = defaultSettings.JobAbilities
            end
        end
    end
end

function Migration_v7:getDescription()
    return "Adding abilities to nuke settings."
end

return Migration_v7




