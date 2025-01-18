---------------------------
-- Moves songs and pianissimo songs to a song set.
-- @class module
-- @name Migration_v25

local Migration = require('settings/migrations/migration')
local Migration_v25 = setmetatable({}, { __index = Migration })
Migration_v25.__index = Migration_v25
Migration_v25.__class = "Migration_v25"

function Migration_v25.new()
    local self = setmetatable(Migration.new(), Migration_v25)
    return self
end

function Migration_v25:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
            and trustSettings:getSettings().Default.SongSettings.SongSets == nil
end

function Migration_v25:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName].SongSettings
        currentSettings.SongSets = {}
        currentSettings.SongSets.Default = {}
        currentSettings.SongSets.Default.Songs = currentSettings.Songs
        currentSettings.SongSets.Default.PianissimoSongs = currentSettings.PianissimoSongs
        currentSettings.Songs = nil
        currentSettings.PianissimoSongs = nil
    end
end

function Migration_v25:getDescription()
    return "Creating song sets."
end

return Migration_v25




