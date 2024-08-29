---------------------------
-- Move all Bard settings under SongSettings.
-- @class module
-- @name Migration_v1

local Migration = require('settings/migrations/migration')
local Migration_v2 = setmetatable({}, { __index = Migration })
Migration_v2.__index = Migration_v2
Migration_v2.__class = "Migration_v2"

function Migration_v2.new()
    local self = setmetatable(Migration.new(), Migration_v2)
    return self
end

function Migration_v2:shouldPerform(trustSettings, _, _)
    return L{ 'BLU' }:contains(trustSettings.jobNameShort)
end

function Migration_v2:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local settings = trustSettings:getSettings()[modeName]
        if not settings.BlueMagicSettings then
            local defaultSettings = T(trustSettings:getDefaultSettings()):clone()

            local currentSettings = trustSettings:getSettings()[modeName]
            currentSettings.BlueMagicSettings = defaultSettings.Default.BlueMagicSettings
        end
    end
end

return Migration_v2




