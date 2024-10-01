---------------------------
-- Add ReadyMoveSkillSettings to weapon skill settings for BST.
-- @class module
-- @name Migration_v4

local Migration = require('settings/migrations/migration')
local Migration_v4 = setmetatable({}, { __index = Migration })
Migration_v4.__index = Migration_v4
Migration_v4.__class = "Migration_v4"

function Migration_v4.new()
    local self = setmetatable(Migration.new(), Migration_v4)
    return self
end

function Migration_v4:shouldPerform(trustSettings, _, _)
    return L{ 'BST' }:contains(trustSettings.jobNameShort)
end

function Migration_v4:perform(_, _, weaponSkillSettings)
    local defaultSettings = T(weaponSkillSettings:getDefaultSettings()):clone()

    local modeNames = list.subtract(L(T(weaponSkillSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = weaponSkillSettings:getSettings()[modeName]
        currentSettings.Skills = defaultSettings.Default.Skills
    end
end

function Migration_v4:getDescription()
    return "Updating weapon skill settings for Beastmaster."
end

return Migration_v4