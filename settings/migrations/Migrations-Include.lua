local Migration = require('settings/migrations/migration')

---------------------------
-- Move all Bard settings under SongSettings.
-- @class module
-- @name Migration_v1

local Migration_v1 = setmetatable({}, { __index = Migration })
Migration_v1.__index = Migration_v1
Migration_v1.__class = "Migration_v1"

function Migration_v1.new()
    local self = setmetatable(Migration.new(), Migration_v1)
    return self
end

function Migration_v1:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_v1:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local settings = trustSettings:getSettings()[modeName]
        if not settings.SongSettings then
            settings.SongSettings = {}
            local keysToMigrate = L{ 'NumSongs', 'SongDuration', 'SongDelay', 'DummySongs', 'Songs' }
            for key in keysToMigrate:it() do
                if settings[key] then
                    settings.SongSettings[key] = settings[key]
                    settings[key] = nil
                end
            end
            settings.SongSettings.PianissimoSongs = settings.PartyBuffs
            settings.PartyBuffs = nil
        end
    end
end

function Migration_v1:getDescription()
    return "Updating Bard job settings."
end

---------------------------
-- Add BlueMagicSettings to Blue Magic job settings.
-- @class module
-- @name Migration_v2

local Migration_v2 = setmetatable({}, { __index = Migration })
Migration_v2.__index = Migration_v2
Migration_v2.__class = "Migration_v2"

function Migration_v2.new()
    local self = setmetatable(Migration.new(), Migration_v2)
    return self
end

function Migration_v2:shouldPerform(trustSettings, _, _)
    return L{ 'BLU' }:contains(trustSettings.jobNameShort)
end

function Migration_v2:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local settings = trustSettings:getSettings()[modeName]
        if not settings.BlueMagicSettings then
            local defaultSettings = T(trustSettings:getDefaultSettings()):clone()

            local currentSettings = trustSettings:getSettings()[modeName]
            currentSettings.BlueMagicSettings = defaultSettings.Default.BlueMagicSettings
        end
    end
end

function Migration_v2:getDescription()
    return "Updating Blue Mage job settings."
end

---------------------------
-- Add Default gambits for Addendum: White and Addendum: Black.
-- @class module
-- @name Migration_v3

local Migration_v3 = setmetatable({}, { __index = Migration })
Migration_v3.__index = Migration_v3
Migration_v3.__class = "Migration_v3"

function Migration_v3.new()
    local self = setmetatable(Migration.new(), Migration_v3)
    return self
end

function Migration_v3:shouldPerform(trustSettings, _, _)
    return L{ 'SCH' }:contains(trustSettings.jobNameShort)
end

function Migration_v3:perform(trustSettings, _, _)
    local defaultSettings = T(trustSettings:getDefaultSettings()):clone()

    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        currentSettings.GambitSettings.Default = defaultSettings.Default.GambitSettings.Default
    end
end

function Migration_v3:getDescription()
    return "Updating default gambits for Scholar."
end

---------------------------
-- Add ReadyMoveSkillSettings to weapon skill settings for BST.
-- @class module
-- @name Migration_v4

local Migration_v4 = setmetatable({}, { __index = Migration })
Migration_v4.__index = Migration_v4
Migration_v4.__class = "Migration_v4"

function Migration_v4.new()
    local self = setmetatable(Migration.new(), Migration_v4)
    return self
end

function Migration_v4:shouldPerform(trustSettings, _, _)
    return L{ 'BST' }:contains(trustSettings.jobNameShort)
end

function Migration_v4:perform(_, _, weaponSkillSettings)
    local defaultSettings = T(weaponSkillSettings:getDefaultSettings()):clone()

    local modeNames = list.subtract(L(T(weaponSkillSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = weaponSkillSettings:getSettings()[modeName]
        currentSettings.Skills = defaultSettings.Default.Skills
    end
end

function Migration_v4:getDescription()
    return "Updating weapon skill settings for Beastmaster."
end

---------------------------
-- Fixing issue where pianissimo songs have a nil job names.
-- @class module
-- @name Migration_v5

local Migration_v5 = setmetatable({}, { __index = Migration })
Migration_v5.__index = Migration_v5
Migration_v5.__class = "Migration_v5"

function Migration_v5.new()
    local self = setmetatable(Migration.new(), Migration_v5)
    return self
end

function Migration_v5:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_v5:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local songs = trustSettings:getSettings()[modeName].SongSettings.PianissimoSongs
        for song in songs:it() do
            if song:get_job_names() == nil then
                song:set_job_names(L{})
            end
        end
    end
end

function Migration_v5:getDescription()
    return "Updating job names for pianissimo songs."
end

---------------------------
-- Migrating AutoFood to a gambit.
-- @class module
-- @name Migration_v6

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
    foodName = foodName or 'Grape Daifuku'
    return Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new(trustSettings.jobNameShort)}, UseItem.new(foodName, L{ItemCountCondition.new(foodName, 1, ">=")}), "Self", L{"food"})
end

function Migration_v6:getDescription()
    return "Creating gambit for auto food."
end

---------------------------
-- Adding JobAbilities key to NukeSettings.
-- @class module
-- @name Migration_v7

local Migration_v7 = setmetatable({}, { __index = Migration })
Migration_v7.__index = Migration_v7
Migration_v7.__class = "Migration_v7"

function Migration_v7.new()
    local self = setmetatable(Migration.new(), Migration_v7)
    return self
end

function Migration_v7:shouldPerform(trustSettings, _, _)
    local defaultSettings = trustSettings:getDefaultSettings()
    return defaultSettings.Default.NukeSettings ~= nil
end

function Migration_v7:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.NukeSettings then
            if currentSettings.NukeSettings.JobAbilities == nil then
                local defaultSettings = T(trustSettings:getDefaultSettings().Default.NukeSettings):clone()
                currentSettings.NukeSettings.JobAbilities = defaultSettings.JobAbilities
            end
        end
    end
end

function Migration_v7:getDescription()
    return "Adding abilities to nuke settings."
end

---------------------------
-- Adding JobAbilities key to WeaponSkillSettings.
-- @class module
-- @name Migration_v8

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

---------------------------
-- Remove mages from default melee songs to avoid pianissimo loops.
-- @class module
-- @name Migration_v9

local Migration_v9 = setmetatable({}, { __index = Migration })
Migration_v9.__index = Migration_v9
Migration_v9.__class = "Migration_v9"

function Migration_v9.new()
    local self = setmetatable(Migration.new(), Migration_v9)
    return self
end

function Migration_v9:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_v9:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local songs = trustSettings:getSettings()[modeName].SongSettings.Songs
        for song in songs:it() do
            if S{ 'Blade Madrigal', 'Valor Minuet V', 'Valor Minuet IV', 'Valor Minuet III' }:contains(song:get_name()) then
                local job_names = song:get_job_names() or L{}
                song:set_job_names(job_names:filter(function(job_name_short)
                    return not S{ 'BLM', 'WHM', 'GEO', 'SCH' }:contains(job_name_short)
                end))
            end
        end
    end
end

function Migration_v9:getDescription()
    return "Removing mages from melee songs."
end

---------------------------
-- Moves pull targets to PullSettings.
-- @class module
-- @name Migration_v10

local Migration_v10 = setmetatable({}, { __index = Migration })
Migration_v10.__index = Migration_v10
Migration_v10.__class = "Migration_v10"

function Migration_v10.new()
    local self = setmetatable(Migration.new(), Migration_v10)
    return self
end

function Migration_v10:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.PullSettings.Targets == nil
end

function Migration_v10:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].PullSettings.Targets = L{
            "Locus Ghost Crab",
            "Locus Dire Bat",
            "Locus Armet Beetle",
        }
    end
end

function Migration_v10:getDescription()
    return "Moving pull targets to job settings."
end

---------------------------
-- Add Scholar main job condition to certain buffs.
-- @class module
-- @name Migration_v11

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

---------------------------
-- Moves JobAbilties to SelfBuffs.
-- @class module
-- @name Migration_v12

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

---------------------------
-- Remove jug pets abilities from self buffs.
-- @class module
-- @name Migration_v13

local Migration_v13 = setmetatable({}, { __index = Migration })
Migration_v13.__index = Migration_v13
Migration_v13.__class = "Migration_v13"

function Migration_v13.new()
    local self = setmetatable(Migration.new(), Migration_v13)
    return self
end

function Migration_v13:shouldPerform(trustSettings, _, _)
    return L{ 'BST' }:contains(trustSettings.jobNameShort)
end

function Migration_v13:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].SelfBuffs = defaultSettings.SelfBuffs
    end
end

function Migration_v13:getDescription()
    return "Remove jug pet abilities from self buffs."
end

---------------------------
-- Adds GearSwapSettings to all job settings files.
-- @class module
-- @name Migration_v14

local Migration_v14 = setmetatable({}, { __index = Migration })
Migration_v14.__index = Migration_v14
Migration_v14.__class = "Migration_v14"

function Migration_v14.new()
    local self = setmetatable(Migration.new(), Migration_v14)
    return self
end

function Migration_v14:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.GearSwapSettings == nil
end

function Migration_v14:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].GearSwapSettings = defaultSettings.GearSwapSettings
    end
end

function Migration_v14:getDescription()
    return "Adding gear swap settings."
end

---------------------------
-- Add nuke settings to Dark Knight.
-- @class module
-- @name Migration_v15

local Migration_v15 = setmetatable({}, { __index = Migration })
Migration_v15.__index = Migration_v15
Migration_v15.__class = "Migration_v15"

function Migration_v15.new()
    local self = setmetatable(Migration.new(), Migration_v15)
    return self
end

function Migration_v15:shouldPerform(trustSettings, _, _)
    return L{ 'DRK' }:contains(trustSettings.jobNameShort)
end

function Migration_v15:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.NukeSettings == nil then
            local defaultSettings = T(trustSettings:getDefaultSettings().Default.NukeSettings):clone()
            currentSettings.NukeSettings = defaultSettings
        end
    end
end

function Migration_v15:getDescription()
    return "Add nuke settings."
end

---------------------------
-- Add nuke settings to Blue Mage.
-- @class module
-- @name Migration_v16

local Migration_v16 = setmetatable({}, { __index = Migration })
Migration_v16.__index = Migration_v16
Migration_v16.__class = "Migration_v16"

function Migration_v16.new()
    local self = setmetatable(Migration.new(), Migration_v16)
    return self
end

function Migration_v16:shouldPerform(trustSettings, _, _)
    return L{ 'BLU' }:contains(trustSettings.jobNameShort)
end

function Migration_v16:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName]
        if currentSettings.NukeSettings == nil then
            local defaultSettings = T(trustSettings:getDefaultSettings().Default.NukeSettings):clone()
            currentSettings.NukeSettings = defaultSettings
        end
    end
end

function Migration_v16:getDescription()
    return "Add nuke settings."
end

---------------------------
-- Adding jobs to songs with no job names.
-- @class module
-- @name Migration_17

local Migration_17 = setmetatable({}, { __index = Migration })
Migration_17.__index = Migration_17
Migration_17.__class = "Migration_17"

function Migration_17.new()
    local self = setmetatable(Migration.new(), Migration_17)
    return self
end

function Migration_17:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
end

function Migration_17:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local defaultSettings = T(trustSettings:getDefaultSettings().Default.SongSettings):clone()
        local songs = trustSettings:getSettings()[modeName].SongSettings.Songs
        for song in songs:it() do
            if song:get_job_names():empty() then
                trustSettings:getSettings()[modeName].SongSettings.Songs = defaultSettings.Songs
                break
            end
        end
    end
end

function Migration_17:getDescription()
    return "Adding jobs to songs."
end

---------------------------
-- Adds TargetSettings to all job settings files.
-- @class module
-- @name Migration_v18

local Migration_v18 = setmetatable({}, { __index = Migration })
Migration_v18.__index = Migration_v18
Migration_v18.__class = "Migration_v18"

function Migration_v18.new()
    local self = setmetatable(Migration.new(), Migration_v18)
    return self
end

function Migration_v18:shouldPerform(trustSettings, _, _)
    return trustSettings:getSettings().Default.TargetSettings == nil
end

function Migration_v18:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        trustSettings:getSettings()[modeName].TargetSettings = defaultSettings.TargetSettings
    end
end

function Migration_v18:getDescription()
    return "Adding target settings."
end

---------------------------
-- Adds Entrust spell to Geomancy settings.
-- @class module
-- @name Migration_v19

local Migration_v19 = setmetatable({}, { __index = Migration })
Migration_v19.__index = Migration_v19
Migration_v19.__class = "Migration_v19"

function Migration_v19.new()
    local self = setmetatable(Migration.new(), Migration_v19)
    return self
end

function Migration_v19:shouldPerform(trustSettings, _, _)
    return L{ 'GEO' }:contains(trustSettings.jobNameShort)
end

function Migration_v19:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    local defaultSettings = T(trustSettings:getDefaultSettings().Default):clone()
    for modeName in modeNames:it() do
        if trustSettings:getSettings()[modeName].Geomancy == nil then
            trustSettings:getSettings()[modeName].Geomancy = defaultSettings.Geomancy
        else
            trustSettings:getSettings()[modeName].Geomancy.Entrust = defaultSettings.Geomancy.Entrust
        end
    end
end

function Migration_v19:getDescription()
    return "Adding entrust to geomancy settings."
end

---------------------------
-- Migrating debuff settings to use gambits.
-- @class module
-- @name Migration_v20

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

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
                local gambit = Gambit.new(GambitTarget.TargetType.Enemy, debuff.conditions, debuff, "Enemy")
                debuff.conditions = L{}
                return gambit
            end)
        }
        currentSettings.Debuffs = nil
    end
end

function Migration_v20:getDescription()
    return "Updating debuff settings."
end

---------------------------
-- Migrating buff settings to use gambits.
-- @class module
-- @name Migration_v21

local BloodPactWard = require('cylibs/battle/abilities/blood_pact_ward')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Migration_v21 = setmetatable({}, { __index = Migration })
Migration_v21.__index = Migration_v21
Migration_v21.__class = "Migration_v21"

function Migration_v21.new()
    local self = setmetatable(Migration.new(), Migration_v21)
    return self
end

function Migration_v21:shouldPerform(trustSettings, _, _)
    if trustSettings.jobNameShort == 'SCH' then
        return trustSettings:getSettings().Default.LightArts and (trustSettings:getSettings().Default.LightArts.SelfBuffs ~= nil or trustSettings:getSettings().Default.LightArts.PartyBuffs ~= nil)
                or trustSettings:getSettings().Default.DarkArts and (trustSettings:getSettings().Default.DarkArts.SelfBuffs ~= nil or trustSettings:getSettings().Default.DarkArts.PartyBuffs ~= nil)
    end
    return trustSettings:getSettings().Default.SelfBuffs ~= nil or trustSettings:getSettings().Default.PartyBuffs ~= nil
end

function Migration_v21:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local allSettings = L{ trustSettings:getSettings()[modeName] }
        if trustSettings.jobNameShort == 'SCH' then
            allSettings = L{ trustSettings:getSettings()[modeName].LightArts, trustSettings:getSettings()[modeName].DarkArts }:compact_map()
        end

        for currentSettings in allSettings:it() do
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
                        buff = BloodPactWard.new(buff:get_name())
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
end

function Migration_v21:getDescription()
    return "Updating buff settings."
end

---------------------------
-- Migrating nuke settings to use gambits.
-- @class module
-- @name Migration_v22

local BloodPactMagic = require('cylibs/battle/abilities/blood_pact_magic')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

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

---------------------------
-- Migrating pull abilities to use gambits.
-- @class module
-- @name Migration_v23

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

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

---------------------------
-- Merge Light Arts and Dark Arts buffs.
-- @class module
-- @name Migration_v24

local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

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

---------------------------
-- Moves songs and pianissimo songs to a song set.
-- @class module
-- @name Migration_v25

local Migration_v25 = setmetatable({}, { __index = Migration })
Migration_v25.__index = Migration_v25
Migration_v25.__class = "Migration_v25"

function Migration_v25.new()
    local self = setmetatable(Migration.new(), Migration_v25)
    return self
end

function Migration_v25:shouldPerform(trustSettings, _, _)
    return L{ 'BRD' }:contains(trustSettings.jobNameShort)
            and trustSettings:getSettings().Default.SongSettings.SongSets == nil
end

function Migration_v25:perform(trustSettings, _, _)
    local modeNames = list.subtract(L(T(trustSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = trustSettings:getSettings()[modeName].SongSettings
        currentSettings.SongSets = {}
        currentSettings.SongSets.Default = {}
        currentSettings.SongSets.Default.Songs = currentSettings.Songs
        currentSettings.SongSets.Default.PianissimoSongs = currentSettings.PianissimoSongs
        currentSettings.Songs = nil
        currentSettings.PianissimoSongs = nil
    end
end

function Migration_v25:getDescription()
    return "Creating song sets."
end

---------------------------
-- Creates ReactionSettings.
-- @class module
-- @name Migration_v26

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

---------------------------
-- Migrates remote commands whitelist to database.
-- @class module
-- @name Migration_v27

local Migration_v27 = setmetatable({}, { __index = Migration })
Migration_v27.__index = Migration_v27
Migration_v27.__class = "Migration_v27"

function Migration_v27.new()
    local self = setmetatable(Migration.new(), Migration_v27)
    return self
end

function Migration_v27:shouldPerform(_, addonSettings, _)
    return addonSettings:getSettings().remote_commands and addonSettings:getSettings().remote_commands.whitelist
            and not L(addonSettings:getSettings().remote_commands.whitelist):empty()
end

function Migration_v27:perform(_, addonSettings, _)
    local User = require('settings/settings').Whitelist

    local whitelist = L(addonSettings:getSettings().remote_commands.whitelist)
    for name in whitelist:it() do
        local user = User({
            id = name
        })
        user:save()
    end
    addonSettings:getSettings().remote_commands.whitelist = L{}
    addonSettings:saveSettings(true)
end

function Migration_v27:getDescription()
    return "Migrating remote commands whitelist."
end

---------------------------
-- Migrates skillchains to gambits.
-- @class module
-- @name Migration_v28

local Migration_v28 = setmetatable({}, { __index = Migration })
Migration_v28.__index = Migration_v28
Migration_v28.__class = "Migration_v28"

function Migration_v28.new()
    local self = setmetatable(Migration.new(), Migration_v28)
    return self
end

function Migration_v28:shouldPerform(_, _, weaponSkillSettings)
    return weaponSkillSettings ~= nil
end

function Migration_v28:perform(_, _, weaponSkillSettings)
    local modeNames = list.subtract(L(T(weaponSkillSettings:getSettings()):keyset()), L{'Version','Migrations'})
    for modeName in modeNames:it() do
        local currentSettings = weaponSkillSettings:getSettings()[modeName]
        currentSettings.Skillchain = currentSettings.Skillchain:map(function(ability)
            if ability.__type == Gambit.__type then
                return ability
            else
                local gambit = Gambit.new("Enemy", ability.conditions, ability, "Self", L{"skillchain"})
                ability.conditions = L{}
                return gambit
            end
        end)
    end
end

function Migration_v28:getDescription()
    return "Migrating weapon skills settings."
end

return {
    Migration_v1 = Migration_v1,
    Migration_v2 = Migration_v2,
    Migration_v3 = Migration_v3,
    Migration_v4 = Migration_v4,
    Migration_v5 = Migration_v5,
    Migration_v6 = Migration_v6,
    Migration_v7 = Migration_v7,
    Migration_v8 = Migration_v8,
    Migration_v9 = Migration_v9,
    Migration_v10 = Migration_v10,
    Migration_v11 = Migration_v11,
    Migration_v12 = Migration_v12,
    Migration_v13 = Migration_v13,
    Migration_v14 = Migration_v14,
    Migration_v15 = Migration_v15,
    Migration_v16 = Migration_v16,
    Migration_v17 = Migration_17,
    Migration_v18 = Migration_v18,
    Migration_v19 = Migration_v19,
    Migration_v20 = Migration_v20,
    Migration_v21 = Migration_v21,
    Migration_v22 = Migration_v22,
    Migration_v23 = Migration_v23,
    Migration_v24 = Migration_v24,
    Migration_v25 = Migration_v25,
    Migration_v26 = Migration_v26,
    Migration_v27 = Migration_v27,
    Migration_v28 = Migration_v28,
}

