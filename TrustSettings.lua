local Event = require('cylibs/events/Luvent')
local FileIO = require('files')

local serializer_util = require('cylibs/util/serializer_util')

require('logger')

local TrustSettings = {}
TrustSettings.__index = TrustSettings
TrustSettings.__type = "TrustSettings"

------
--- Minimum required settings version for each job
TrustSettings.settingsVersion = {
    WAR = 1,
    WHM = 2,
    RDM = 2,
    PLD = 1,
    BRD = 1,
    SAM = 1,
    DRG = 1,
    BLU = 1,
    PUP = 1,
    SCH = 2,
    RUN = 1,
    MNK = 1,
    BLM = 2,
    THF = 1,
    BST = 1,
    RNG = 1,
    NIN = 1,
    SMN = 1,
    COR = 1,
    DNC = 1,
    GEO = 2,
    DRK = 1,
}

function TrustSettings:onSettingsChanged()
    return self.settingsChanged
end

function TrustSettings.new(jobNameShort, playerName)
    local self = setmetatable({}, TrustSettings)
    self.jobNameShort = jobNameShort
    self.playerName = playerName or windower.ffxi.get_player().name
    self.settingsFolder = 'data/'
    self.backupsFolder = 'backups/'
    self.settingsVersion = TrustSettings.settingsVersion[jobNameShort] or 1
    self.settingsChanged = Event.newEvent()
    self.defaultSettings = {}
    self.settings = {}
    self.isFirstLoad = false
    return self
end

function TrustSettings:loadFile(filePath)
    return coroutine.create(function()
        local settings
        local loadSettings, err = loadfile(filePath)
        if not err then
            settings = loadSettings()
        end
        coroutine.yield(settings, err)
    end)
end

function TrustSettings:loadSettings()
    local filePath = self:getSettingsFilePath()
    if filePath then
        local success, jobSettings, err = coroutine.resume(self:loadFile(filePath))
        if err then
            if not windower.file_exists(filePath) then
                self.isFirstLoad = true
                self:copySettings(true)
                return self:loadSettings()
            else
                addon_system_error(err)
            end
        else
            local success, defaultJobSettings, _ = coroutine.resume(self:loadFile(self:getSettingsFilePath(true)))
            self.defaultSettings = defaultJobSettings
            self.settings = jobSettings
            self.settingsVersion = self.settings.Version or -1
            self:runMigrations(self.settings, self.defaultSettings)
            self:onSettingsChanged():trigger(self.settings)
            return self.settings
        end
    else
        addon_message(123, 'Unable to load trust settings for '..self.jobNameShort)
    end
    return nil
end

function TrustSettings:reloadSettings()
    self:loadSettings()
end

function TrustSettings:getSettingsFilePath(default_settings)
    if default_settings then
        local file_prefix = windower.addon_path..'settings/default/'..self.jobNameShort
        return file_prefix..'.lua'
    else
        local file_prefix = windower.addon_path..self.settingsFolder..self.jobNameShort
        return file_prefix..'_'..self.playerName..'.lua'
    end
end

function TrustSettings:getSettingsVersion()
    return self.settingsVersion
end

function TrustSettings:checkSettingsVersion()
    return self:getSettingsVersion() >= self.defaultSettings.Version
end

function TrustSettings:saveToFile(filePath, settings)
    return coroutine.create(function()
        local file = FileIO.new(filePath)
        file:write('-- Settings file for '..self.jobNameShort ..'\nreturn ' .. serializer_util.serialize(settings)) -- Uses our new lua serializer!
        coroutine.yield()
    end)
end

function TrustSettings:saveSettings(saveToFile)
    if saveToFile then
        local filePath = self.settingsFolder..self.jobNameShort..'_'..self.playerName..'.lua'
        local _ = coroutine.resume(self:saveToFile(filePath, self.settings))
    end
    self:onSettingsChanged():trigger(self.settings)
end

function TrustSettings:copySettings(override)
    local filePath = self.settingsFolder..self.jobNameShort..'_'..self.playerName..'.lua'
    local playerSettings = FileIO.new(filePath)
    if not playerSettings:exists() or override then
        if playerSettings:exists() then
            self:backupSettings(filePath)
        end
        local defaultSettings = FileIO.new('settings/default/'..self.jobNameShort..'.lua')
        playerSettings:write(defaultSettings:read())

        --addon_message(207, 'Copied default settings to '..filePath)
    end
end

function TrustSettings:createSettings(setName, jobSettings)
    if setName ~= 'Default' and not self.settings[setName] then
        self.settings[setName] = jobSettings or self.settings['Default']

        self:saveSettings(true)
        self:reloadSettings()
    end
end

function TrustSettings:deleteSettings(setName)
    if setName ~= 'Default' and self.settings[setName] then
        self.settings[setName] = nil
        self:saveSettings(true)
    end
end

function TrustSettings:backupSettings(filePath)
    filePath = filePath or self.settingsFolder..self.jobNameShort..'_'..self.playerName..'.lua'
    local playerSettings = FileIO.new(filePath)
    if playerSettings:exists() then
        local backupFilePath = self.settingsFolder..self.backupsFolder..self.jobNameShort..'_'..self.playerName..'.lua'
        local backupSettings = FileIO.new(backupFilePath)
        backupSettings:write(playerSettings:read())

        addon_message(207, 'Backed up old settings to '..backupFilePath)
    end
end

function TrustSettings.migrateSettings(jobNameShort, legacySettings, isPlayer)
    local newSettings = {}
    for name, settings in pairs(legacySettings) do
        newSettings[name] = TrustSettings.encodeSettings(settings)
    end
    local filePath = self.settingsFolder..jobNameShort..'.lua'
    if isPlayer then
        filePath = self.settingsFolder..jobNameShort..'_'..self.playerName..'.lua'
    end
    local file = FileIO.new(filePath)
    file:write('-- ===DO NOT MODIFY THIS FILE=== Settings file for '..jobNameShort ..'\nreturn ' .. T(newSettings):tovstring())
end

function TrustSettings:getSettings()
    return self.settings
end

function TrustSettings:getDefaultSettings()
    return self.defaultSettings
end

function TrustSettings:runMigrations(settings, defaultSettings)
    -- Do not run migrations when impersonating a user
    if self.playerName ~= windower.ffxi.get_player().name then
        return
    end

    local needsMigration = false

    local modeNames = list.subtract(L(T(settings):keyset()), L{'Migrations','Version'})

    for modeName in modeNames:it() do
        local settingsForMode = settings[modeName]
        if not settingsForMode.PullSettings then
            settingsForMode.PullSettings = defaultSettings.Default.PullSettings
            needsMigration = true
        end
        if not settingsForMode.PullSettings.Distance then
            settingsForMode.PullSettings.Distance = 20
            needsMigration = true
        end
        if not settingsForMode.GambitSettings then
            settingsForMode.GambitSettings = {}
            settingsForMode.GambitSettings.Gambits = defaultSettings.Default.GambitSettings.Gambits
            needsMigration = true
        end
        if not settingsForMode.GambitSettings.Default then
            if defaultSettings.Default.GambitSettings and defaultSettings.Default.GambitSettings.Default then
                settingsForMode.GambitSettings.Default = defaultSettings.Default.GambitSettings and defaultSettings.Default.GambitSettings.Default or L{}
                needsMigration = true
            end
        end
    end

    if needsMigration then
        self:saveSettings(true)
    end
end

function TrustSettings:getSetNames()
    local setNames = list.subtract(L(T(self:getSettings()):keyset()), L{'Version','Migrations'})
    return setNames
end

return TrustSettings