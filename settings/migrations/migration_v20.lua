---------------------------
-- Migrating debuff settings to use gambits.
-- @class module
-- @name Migration_v20

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Migration = require('settings/migrations/migration')
local Migration_v20 = setmetatable({}, { __index = Migration })
Migration_v20.__index = Migration_v20
Migration_v20.__class = "Migration_v20"

function Migration_v20.new()
    local self = setmetatable(Migration.new(), Migration_v20)
    return self
end

function Migration_v20:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.Debuffs ~= nil
end

function Migration_v20:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]

        currentSettings.DebuffSettings = {
            Gambits = currentSettings.Debuffs:map(function(debuff)
                return Gambit.new(GambitTarget.TargetType.Enemy, L{}, debuff, "Enemy")
            end)
        }
        currentSettings.Debuffs = nil
    end
end

function Migration_v20:getDescription()
    return "Updating debuff settings."
end

return Migration_v20




