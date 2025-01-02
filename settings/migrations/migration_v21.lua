---------------------------
-- Migrating buff settings to use gambits.
-- @class module
-- @name Migration_v21

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Migration = require('settings/migrations/migration')
local Migration_v21 = setmetatable({}, { __index = Migration })
Migration_v21.__index = Migration_v21
Migration_v21.__class = "Migration_v21"

function Migration_v21.new()
    local self = setmetatable(Migration.new(), Migration_v21)
    return self
end

function Migration_v21:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.SelfBuffs ~= nil or trustSettings:getSettings().Default.PartyBuffs ~= nil
end

function Migration_v21:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]

        local allBuffs = L{}

        if currentSettings.SelfBuffs then
            allBuffs = allBuffs + currentSettings.SelfBuffs:map(function(buff)
                local gambit = Gambit.new(GambitTarget.TargetType.Self, buff.conditions, buff, "Self")
                buff.conditions = L{}
                return gambit
            end)
        end

        if currentSettings.PartyBuffs then
            allBuffs = allBuffs + currentSettings.PartyBuffs:map(function(buff)
                local gambitTarget = GambitTarget.TargetType.Ally
                if trustSettings.jobNameShort == 'SMN' then
                    gambitTarget = GambitTarget.TargetType.Self
                end
                local gambit = Gambit.new(gambitTarget, buff.conditions, buff, gambitTarget)
                buff.conditions = L{}
                return gambit
            end)
        end

        currentSettings.BuffSettings = {
            Gambits = allBuffs
        }
        currentSettings.SelfBuffs = nil
        currentSettings.PartyBuffs = nil
    end
end

function Migration_v21:getDescription()
    return "Updating buff settings."
end

return Migration_v21




