---------------------------
-- Updates default Gambits.
-- @class module
-- @name UpdateDefaultGambitsMigration

local Migration = require('settings/migrations/migration')
local UpdateDefaultGambitsMigration = setmetatable({}, { __index = Migration })
UpdateDefaultGambitsMigration.__index = UpdateDefaultGambitsMigration
UpdateDefaultGambitsMigration.__class = "UpdateDefaultGambitsMigration"

function UpdateDefaultGambitsMigration.new()
    local self = setmetatable(Migration.new(), UpdateDefaultGambitsMigration)
    return self
end

function UpdateDefaultGambitsMigration:shouldPerform(trustSettings, _, _)
    local currentSettings = trustSettings:getSettings().Default
    return currentSettings and currentSettings.GambitSettings and currentSettings.GambitSettings.Default
end

function UpdateDefaultGambitsMigration:perform(trustSettings, _, _)
    local defaultSettings = T(trustSettings:getDefaultSettings()):clone()

    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        currentSettings.GambitSettings.Default = defaultSettings.Default.GambitSettings.Default
    end
end

function UpdateDefaultGambitsMigration:shouldRepeat()
    return true
end

function UpdateDefaultGambitsMigration:getDescription()
    return "Updating default gambits."
end

return UpdateDefaultGambitsMigration




