---------------------------
-- Remove jug pets abilities from self buffs.
-- @class module
-- @name Migration_v13

local Migration = require('settings/migrations/migration')
local Migration_v13 = setmetatable({}, { __index = Migration })
Migration_v13.__index = Migration_v13
Migration_v13.__class = "Migration_v13"

function Migration_v13.new()
    local self = setmetatable(Migration.new(), Migration_v13)
    return self
end

function Migration_v13:shouldPerform(trustSettings, _, _)
    return L{ 'BST' }:contains(trustSettings.jobNameShort)
end

function Migration_v13:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].SelfBuffs = defaultSettings.SelfBuffs
    end
end

function Migration_v13:getDescription()
    return "Remove jug pet abilities from self buffs."
end

return Migration_v13




