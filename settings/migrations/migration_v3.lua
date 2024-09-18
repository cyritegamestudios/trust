---------------------------
-- Add Default gambits for Addendum: White and Addendum: Black.
-- @class module
-- @name Migration_v3

local Migration = require('settings/migrations/migration')
local Migration_v3 = setmetatable({}, { __index = Migration })
Migration_v3.__index = Migration_v3
Migration_v3.__class = "Migration_v3"

function Migration_v3.new()
    local self = setmetatable(Migration.new(), Migration_v3)
    return self
end

function Migration_v3:shouldPerform(trustSettings, _, _)
    return L{ 'SCH' }:contains(trustSettings.jobNameShort)
end

function Migration_v3:perform(trustSettings, _, _)
    local defaultSettings = T(trustSettings:getDefaultSettings()):clone()

    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        currentSettings.GambitSettings.Default = defaultSettings.Default.GambitSettings.Default
    end
end

function Migration_v3:getDescription()
    return "Updating default gambits for Scholar."
end

return Migration_v3




