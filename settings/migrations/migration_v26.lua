---------------------------
-- Creates ReactionSettings.
-- @class module
-- @name Migration_v26

local Migration = require('settings/migrations/migration')
local Migration_v26 = setmetatable({}, { __index = Migration })
Migration_v26.__index = Migration_v26
Migration_v26.__class = "Migration_v26"

function Migration_v26.new()
    local self = setmetatable(Migration.new(), Migration_v26)
    return self
end

function Migration_v26:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.ReactionSettings == nil
end

function Migration_v26:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.ReactionSettings == nil then
            currentSettings.ReactionSettings = {
                Gambits = L{}
            }
        end
        for gambit in currentSettings.GambitSettings.Gambits:it() do
            if gambit:isReaction() then
                currentSettings.ReactionSettings.Gambits:append(gambit)
            end
        end
        currentSettings.GambitSettings.Gambits = currentSettings.GambitSettings.Gambits:filter(function(gambit)
            return not gambit:isReaction()
        end)
    end
end

function Migration_v26:getDescription()
    return "Creating reaction settings."
end

return Migration_v26




