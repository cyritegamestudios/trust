---------------------------
-- Move all Bard settings under SongSettings.
-- @class module
-- @name Migration_v9

local Migration = require('settings/migrations/migration')
local Migration_v9 = setmetatable({}, { __index = Migration })
Migration_v9.__index = Migration_v9
Migration_v9.__class = "Migration_v9"

function Migration_v9.new()
    local self = setmetatable(Migration.new(), Migration_v9)
    return self
end

function Migration_v9:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_v9:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local songs = trustSettings:getSettings()[modeName].SongSettings.Songs
        for song in songs:it() do
            if S{ 'Blade Madrigal', 'Valor Minuet V', 'Valor Minuet IV', 'Valor Minuet III' }:contains(song:get_name()) then
                local job_names = song:get_job_names() or L{}
                song:set_job_names(job_names:filter(function(job_name_short)
                    return not S{ 'BLM', 'WHM', 'GEO', 'SCH' }:contains(job_name_short)
                end))
            end
        end
    end
end

function Migration_v9:getDescription()
    return "Removing mages from melee songs."
end

return Migration_v9




