local Event = require('cylibs/events/Luvent')
local FileIO = require('files')

local serializer_util = require('cylibs/util/serializer_util')

require('logger')

local WeaponSkillSettings = {}
WeaponSkillSettings.__index = WeaponSkillSettings
WeaponSkillSettings.__class = "WeaponSkillSettings"

------
--- Minimum required settings version for each job
WeaponSkillSettings.settingsVersion = {
    WAR = 1,
    WHM = 1,
    RDM = 1,
    PLD = 1,
    BRD = 1,
    SAM = 1,
    DRG = 1,
    BLU = 1,
    PUP = 1,
    SCH = 1,
    RUN = 1,
    MNK = 1,
    BLM = 1,
    THF = 1,
    BST = 1,
    RNG = 1,
    NIN = 1,
    SMN = 1,
    COR = 1,
    DNC = 1,
    GEO = 1,
    DRK = 1,
}

function WeaponSkillSettings:onSettingsChanged()
    return self.settingsChanged
end

function WeaponSkillSettings.new(jobNameShort)
    local self = setmetatable({}, WeaponSkillSettings)
    self.jobNameShort = jobNameShort
    self.settingsFolder = 'data/skillchains/'
    self.backupsFolder = 'backups/skillchains/'
    self.settingsVersion = WeaponSkillSettings.settingsVersion[jobNameShort] or 1
    self.settingsChanged = Event.newEvent()
    self.defaultSettings = {}
    self.settings = {}
    return self
end

function WeaponSkillSettings:loadSettings(verbose)
    local filePath = self:getSettingsFilePath()
    if filePath then
        local loadJobSettings, err = loadfile(filePath)
        if err then
            error(err)
        else
            if verbose then
                addon_message(207, 'Loaded weapon skill settings from '..filePath)
            end
            local loadDefaultJobSettings, _ = loadfile(self:getSettingsFilePath(true))
            self.defaultSettings = loadDefaultJobSettings()
            self.settings = loadJobSettings()
            self.settingsVersion = self.settings.Version or -1
            if not self:checkSettingsVersion() then
                error("Weapon skill settings have been upgraded! A new settings file will be generated for", self.jobNameShort)
                self:copySettings(true)
                return self:loadSettings()
            end
            self:onSettingsChanged():trigger(self.settings)
            return self.settings
        end
    else
        addon_message(207, 'Unable to load weapon skill settings for '..self.jobNameShort)
    end
    return nil
end

function WeaponSkillSettings:reloadSettings()
    return self:loadSettings(false)
end

function WeaponSkillSettings:getSettingsFilePath(default_settings)
    local file_prefix = windower.addon_path..self.settingsFolder..self.jobNameShort
    if windower.file_exists(file_prefix..'_'..windower.ffxi.get_player().name..'.lua') and not default_settings then
        return file_prefix..'_'..windower.ffxi.get_player().name..'.lua'
    elseif windower.file_exists(file_prefix..'.lua') then
        return file_prefix..'.lua'
    end
    return nil
end

function WeaponSkillSettings:getSettingsVersion()
    return self.settingsVersion
end

function WeaponSkillSettings:checkSettingsVersion()
    return self:getSettingsVersion() >= self.defaultSettings.Version
end

function WeaponSkillSettings:saveSettings(saveToFile)
    if saveToFile then
        local filePath = self.settingsFolder..self.jobNameShort..'_'..windower.ffxi.get_player().name..'.lua'

        local file = FileIO.new(filePath)
        file:write('-- Weapon skill settings file for '..self.jobNameShort ..'\nreturn ' .. serializer_util.serialize(self.settings)) -- Uses our new lua serializer!
    end
    self:onSettingsChanged():trigger(self.settings)
end

function WeaponSkillSettings:createSettings(setName)
    if setName ~= 'Default' and not self.settings[setName] then
        self.settings[setName] = self.settings['Default']

        self:saveSettings(true)
        self:reloadSettings()
    end
end

function WeaponSkillSettings:copySettings(override)
    local filePath = self.settingsFolder..self.jobNameShort..'_'..windower.ffxi.get_player().name..'.lua'
    local playerSettings = FileIO.new(filePath)
    if not playerSettings:exists() or override then
        if playerSettings:exists() then
            self:backupSettings(filePath)
        end
        local defaultSettings = FileIO.new(self.settingsFolder..self.jobNameShort..'.lua')
        playerSettings:write(defaultSettings:read())

        addon_message(207, 'Copied default weapon skill settings to '..filePath)
    end
end

function WeaponSkillSettings:backupSettings(filePath)
    local playerSettings = FileIO.new(filePath)
    if playerSettings:exists() then
        local backupFilePath = self.settingsFolder..self.backupsFolder..self.jobNameShort..'_'..windower.ffxi.get_player().name..'.lua'
        local backupSettings = FileIO.new(backupFilePath)
        backupSettings:write(playerSettings:read())

        addon_message(207, 'Backed up old weapon skill settings to '..backupFilePath)
    end
end

function WeaponSkillSettings:allowsDuplicates()
    return false
end

function WeaponSkillSettings:getDefaultSettings()
    return self.defaultSettings
end

function WeaponSkillSettings:getSetNames()
    local setNames = list.subtract(L(T(self:getSettings()):keyset()), L{'Version','Migrations'})
    return setNames
end

function WeaponSkillSettings:getSettings()
    return self.settings
end

return WeaponSkillSettings