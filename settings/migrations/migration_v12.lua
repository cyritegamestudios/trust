---------------------------
-- Moves JobAbilties to SelfBuffs.
-- @class module
-- @name Migration_v12

local Migration = require('settings/migrations/migration')
local Migration_v12 = setmetatable({}, { __index = Migration })
Migration_v12.__index = Migration_v12
Migration_v12.__class = "Migration_v12"

function Migration_v12.new()
    local self = setmetatable(Migration.new(), Migration_v12)
    return self
end

function Migration_v12:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.JobAbilities ~= nil
end

function Migration_v12:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.JobAbilities then
            for jobAbility in currentSettings.JobAbilities:it() do
                currentSettings.SelfBuffs:append(jobAbility)
            end
        end
        currentSettings.JobAbilities = nil
    end
end

function Migration_v12:getDescription()
    return "Moving job ability buffs to self buffs."
end

return Migration_v12




