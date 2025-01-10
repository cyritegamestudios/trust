---------------------------
-- Merge Light Arts and Dark Arts buffs.
-- @class module
-- @name Migration_v24

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Migration = require('settings/migrations/migration')
local Migration_v24 = setmetatable({}, { __index = Migration })
Migration_v24.__index = Migration_v24
Migration_v24.__class = "Migration_v24"

function Migration_v24.new()
    local self = setmetatable(Migration.new(), Migration_v24)
    return self
end

function Migration_v24:shouldPerform(trustSettings, _, _)
    return L{ 'SCH' }:contains(trustSettings.jobNameShort) and trustSettings:getSettings().Default.LightArts ~= nil
            or trustSettings:getSettings().Default.DarkArts ~= nil
end

function Migration_v24:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]

        local gambits = L{}
        for arts in L{ 'LightArts', 'DarkArts' }:it() do
            if currentSettings[arts] and currentSettings[arts].BuffSettings then
                gambits = gambits + currentSettings[arts].BuffSettings.Gambits
            end
            currentSettings[arts] = nil
        end

        currentSettings.BuffSettings = {
            Gambits = gambits
        }
    end
end

function Migration_v24:getDescription()
    return "Merging Light Arts and Dark Arts."
end

return Migration_v24




