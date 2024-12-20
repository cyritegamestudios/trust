---------------------------
-- Adding jobs to songs with no job names.
-- @class module
-- @name Migration_17

local Migration = require('settings/migrations/migration')
local Migration_17 = setmetatable({}, { __index = Migration })
Migration_17.__index = Migration_17
Migration_17.__class = "Migration_17"

function Migration_17.new()
    local self = setmetatable(Migration.new(), Migration_17)
    return self
end

function Migration_17:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_17:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local defaultSettings = T(trustSettings:getDefaultSettings().Default.SongSettings):clone()
        local songs = trustSettings:getSettings()[modeName].SongSettings.Songs
        for song in songs:it() do
            if song:get_job_names():empty() then
                trustSettings:getSettings()[modeName].SongSettings.Songs = defaultSettings.Songs
                break
            end
        end
    end
end

function Migration_17:getDescription()
    return "Adding jobs to songs."
end

return Migration_17




