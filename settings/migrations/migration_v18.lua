---------------------------
-- Adds TargetSettings to all job settings files.
-- @class module
-- @name Migration_v18

local Migration = require('settings/migrations/migration')
local Migration_v18 = setmetatable({}, { __index = Migration })
Migration_v18.__index = Migration_v18
Migration_v18.__class = "Migration_v18"

function Migration_v18.new()
    local self = setmetatable(Migration.new(), Migration_v18)
    return self
end

function Migration_v18:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.TargetSettings == nil
end

function Migration_v18:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].TargetSettings = defaultSettings.TargetSettings
    end
end

function Migration_v18:getDescription()
    return "Adding target settings."
end

return Migration_v18




