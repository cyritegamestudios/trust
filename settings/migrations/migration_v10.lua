---------------------------
-- Moves pull targets to PullSettings.
-- @class module
-- @name Migration_v10

local Migration = require('settings/migrations/migration')
local Migration_v10 = setmetatable({}, { __index = Migration })
Migration_v10.__index = Migration_v10
Migration_v10.__class = "Migration_v10"

function Migration_v10.new()
    local self = setmetatable(Migration.new(), Migration_v10)
    return self
end

function Migration_v10:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.PullSettings.Targets == nil
end

function Migration_v10:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].PullSettings.Targets = L{
            "Locus Ghost Crab",
            "Locus Dire Bat",
            "Locus Armet Beetle",
        }
    end
end

function Migration_v10:getDescription()
    return "Moving pull targets to job settings."
end

return Migration_v10




