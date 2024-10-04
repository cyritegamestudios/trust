---------------------------
-- Migrating AutoFood to a gambit.
-- @class module
-- @name Migration_v6

local Migration = require('settings/migrations/migration')
local Migration_v6 = setmetatable({}, { __index = Migration })
Migration_v6.__index = Migration_v6
Migration_v6.__class = "Migration_v6"

function Migration_v6.new()
    local self = setmetatable(Migration.new(), Migration_v6)
    return self
end

function Migration_v6:shouldPerform(_, _, _)
    return true
end

function Migration_v6:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.AutoFood then
            if currentSettings.GambitSettings.Gambits:firstWhere(function(gambit) return gambit:getTags():contains('food') end) == nil then
                currentSettings.GambitSettings.Gambits:append(self:getDefaultFoodGambit(trustSettings, currentSettings.AutoFood))
            end
            currentSettings.AutoFood = nil
        end
    end
end

function Migration_v6:getDefaultFoodGambit(trustSettings, foodName)
    return Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new(trustSettings.jobNameShort)}, UseItem.new(foodName, L{ItemCountCondition.new(foodName, 1, ">=")}), "Self", L{"food"})
end

function Migration_v6:getDescription()
    return "Creating gambit for auto food."
end

return Migration_v6




