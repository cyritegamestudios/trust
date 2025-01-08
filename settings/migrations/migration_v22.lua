---------------------------
-- Migrating nuke settings to use gambits.
-- @class module
-- @name Migration_v22

local BloodPactMagic = require('cylibs/battle/abilities/blood_pact_magic')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Migration = require('settings/migrations/migration')
local Migration_v22 = setmetatable({}, { __index = Migration })
Migration_v22.__index = Migration_v22
Migration_v22.__class = "Migration_v22"

function Migration_v22.new()
    local self = setmetatable(Migration.new(), Migration_v22)
    return self
end

function Migration_v22:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.NukeSettings
end

function Migration_v22:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName].NukeSettings
        if currentSettings.Spells then
            local allNukes = currentSettings.Spells:map(function(spell)
                local gambitTarget = GambitTarget.TargetType.Enemy
                if trustSettings.jobNameShort == 'SMN' then
                    gambitTarget = GambitTarget.TargetType.Enemy
                    spell = BloodPactMagic.new(spell:get_name())
                end
                local gambit = Gambit.new(gambitTarget, spell.conditions, spell, gambitTarget, L{"Nukes"})
                spell.conditions = L{}
                return gambit
            end)
            currentSettings.Gambits = allNukes
            currentSettings.Spells = nil
        end
    end
end

function Migration_v22:getDescription()
    return "Updating nukes."
end

return Migration_v22




