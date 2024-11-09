---------------------------
-- Add Scholar main job condition to certain buffs.
-- @class module
-- @name Migration_v11

local Migration = require('settings/migrations/migration')
local Migration_v11 = setmetatable({}, { __index = Migration })
Migration_v11.__index = Migration_v11
Migration_v11.__class = "Migration_v11"

function Migration_v11.new()
    local self = setmetatable(Migration.new(), Migration_v11)
    return self
end

function Migration_v11:shouldPerform(trustSettings, _, _)
    return L{ 'SCH' }:contains(trustSettings.jobNameShort)
end

function Migration_v11:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local selfBuffs = trustSettings:getSettings()[modeName].LightArts.SelfBuffs
        for buff in selfBuffs:it() do
            if S{ 'Protect', 'Shell', 'Regen' }:contains(buff.original_spell_name) then
                local matches = buff:get_conditions():filter(function(c)
                    return c.__class == MainJobCondition.__class
                end)
                if matches:length() == 0 then
                    buff:add_condition(MainJobCondition.new('SCH'))
                end
            end
            if S{ 'Aurorastorm' }:contains(buff.original_spell_name) then
                local matches = buff:get_conditions():filter(function(c)
                    return c.__class == NotCondition.__class
                end)
                if matches:length() == 0 then
                    buff:add_condition(NotCondition.new(L{ MainJobCondition.new('SCH') }))
                end
            end
        end
    end
end

function Migration_v11:getDescription()
    return "Updating sub job buffs."
end

return Migration_v11




