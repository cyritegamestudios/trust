---------------------------
-- Move all Bard settings under SongSettings.
-- @class module
-- @name Migration_v1

local Migration = require('settings/migrations/migration')
local Migration_v1 = setmetatable({}, { __index = Migration })
Migration_v1.__index = Migration_v1
Migration_v1.__class = "Migration_v1"

function Migration_v1.new()
    local self = setmetatable(Migration.new(), Migration_v1)
    return self
end

function Migration_v1:perform(trustSettings, _, _)
    if not trustSettings.jobNameShort == 'BRD' then
        return true
    end

    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local settings = trustSettings:getSettings()[modeName]
        if not settings.SongSettings then
            settings.SongSettings = {}
            local keysToMigrate = L{ 'NumSongs', 'SongDuration', 'SongDelay', 'DummySongs', 'Songs' }
            for key in keysToMigrate:it() do
                if settings[key] then
                    settings.SongSettings[key] = settings[key]
                    settings[key] = nil
                end
            end
            settings.SongSettings.PianissimoSongs = settings.PartyBuffs
            settings.PartyBuffs = nil
        end
    end
    return true
end

return Migration_v1




