---------------------------
-- Fixing issue where pianissimo songs have a nil job names.
-- @class module
-- @name Migration_v5

local Migration = require('settings/migrations/migration')
local Migration_v5 = setmetatable({}, { __index = Migration })
Migration_v5.__index = Migration_v5
Migration_v5.__class = "Migration_v5"

function Migration_v5.new()
    local self = setmetatable(Migration.new(), Migration_v5)
    return self
end

function Migration_v5:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_v5:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local songs = trustSettings:getSettings()[modeName].SongSettings.PianissimoSongs
        for song in songs:it() do
            if song:get_job_names() == nil then
                song:set_job_names(L{})
            end
        end
    end
end

function Migration_v5:getDescription()
    return "Updating job names for pianissimo songs."
end

return Migration_v5




