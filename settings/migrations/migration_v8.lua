---------------------------
-- Adding JobAbilities key to WeaponSkillSettings.
-- @class module
-- @name Migration_v8

local Migration = require('settings/migrations/migration')
local Migration_v8 = setmetatable({}, { __index = Migration })
Migration_v8.__index = Migration_v8
Migration_v8.__class = "Migration_v8"

function Migration_v8.new()
    local self = setmetatable(Migration.new(), Migration_v8)
    return self
end

function Migration_v8:shouldPerform(_, _, weaponSkillSettings)
    return weaponSkillSettings ~= nil
end

function Migration_v8:perform(_, _, weaponSkillSettings)
    local modeNames = list.subtract(L(T(weaponSkillSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = weaponSkillSettings:getSettings()[modeName]
        if currentSettings.JobAbilities == nil then
            local defaultSettings = T(weaponSkillSettings:getDefaultSettings().Default):clone()
            currentSettings.JobAbilities = defaultSettings.JobAbilities
        end
    end
end

function Migration_v8:getDescription()
    return "Adding abilities to weapon skill settings."
end

return Migration_v8




