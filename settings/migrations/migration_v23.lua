---------------------------
-- Migrating pull abilities to use gambits.
-- @class module
-- @name Migration_v23

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Migration = require('settings/migrations/migration')
local Migration_v23 = setmetatable({}, { __index = Migration })
Migration_v23.__index = Migration_v23
Migration_v23.__class = "Migration_v23"

function Migration_v23.new()
    local self = setmetatable(Migration.new(), Migration_v23)
    return self
end

function Migration_v23:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.PullSettings.Gambits == nil
end

function Migration_v23:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName].PullSettings
        currentSettings.Gambits = L{}
        if currentSettings.Abilities then
            currentSettings.Gambits = currentSettings.Abilities:map(function(ability)
                local gambit = Gambit.new(GambitTarget.TargetType.Enemy, ability.conditions, ability, GambitTarget.TargetType.Enemy, L{"Pulling"})
                ability.conditions = L{}
                return gambit
            end)
            currentSettings.Abilities = nil
        end
    end
end

function Migration_v23:getDescription()
    return "Updating pull abilities."
end

return Migration_v23




