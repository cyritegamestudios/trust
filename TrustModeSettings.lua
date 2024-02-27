local Event = require('cylibs/events/Luvent')
local FileIO = require('files')
local tables_ext = require('cylibs/util/extensions/tables')

require('logger')

local TrustModeSettings = {}
TrustModeSettings.__index = TrustModeSettings
TrustModeSettings.__type = "TrustModeSettings"

state.TrustMode = M{['description'] = 'Trust Mode', T{}}

function TrustModeSettings:onSettingsChanged()
    return self.settingsChanged
end

function TrustModeSettings.new(jobNameShort)
    local self = setmetatable({}, TrustModeSettings)

    self.jobNameShort = jobNameShort
    self.settingsChanged = Event.newEvent()
    self.settings = {}

    return self
end

function TrustModeSettings:loadSettings()
    local filePath = self:getSettingsFilePath()
    if filePath then
        local loadModeSettings, err = loadfile(filePath)
        if err then
            error(err)
        else
            addon_message(207, 'Loaded mode settings from '..filePath)
            self.settings = loadModeSettings()

            for setName, modeSet in pairs(T(self.settings)) do
                if setName ~= 'Default' then
                    self.settings[setName] = table.merge(T(self.settings['Default']), modeSet)
                end
            end

            local options = L(T(self.settings):keyset()):sort(function (modeSet1, modeSet2)
                if modeSet1 == 'Default' then
                    return true
                elseif modeSet2 == 'Default' then
                    return false
                end
                return modeSet1 < modeSet2
            end)

            state.TrustMode:options(options:unpack())
            state.TrustMode:reset()

            self:onSettingsChanged():trigger(self:getSettings())
        end
    else
        addon_message(207, 'Unable to load mode settings for '..self.jobNameShort)
    end
end

function TrustModeSettings:reloadSettings()
    self:loadSettings()
end

function TrustModeSettings:getSettingsFilePath()
    local file_prefix = windower.addon_path..'data/modes/'..self.jobNameShort
    if windower.file_exists(file_prefix..'_'..windower.ffxi.get_player().name..'.lua') then
        return file_prefix..'_'..windower.ffxi.get_player().name..'.lua'
    elseif windower.file_exists(file_prefix..'.lua') then
        return file_prefix..'.lua'
    end
    addon_message(100, 'No default trust modes for '..(self.jobNameShort or 'nil'))
    return nil
end

function TrustModeSettings:saveSettings(setName)
    local setName = setName or state.TrustMode.value

    local trust_modes = {}
    for state_name, _ in pairs(state) do
        if state_name ~= 'TrustMode' then
            trust_modes[state_name:lower()] = state[state_name].value
        end
    end

    local newSettings = T(self.settings):copy()
    newSettings[setName] = trust_modes

    for existingSetName, modeSet in pairs(newSettings) do
        if existingSetName ~= 'Default' then
            newSettings[existingSetName] = table.diff(modeSet, self.settings['Default'])
        end
    end

    local file_paths = L{
        'data/modes/'..player.main_job_name_short ..'_'..windower.ffxi.get_player().name..'.lua',
    }
    for file_path in file_paths:it() do
        local trust_modes_file = files.new(file_path)
        if not trust_modes_file:exists() then
            addon_message(207, 'Created trust modes override '..file_path)
        else
            addon_message(207, 'Updated trust modes for '..setName..' '..file_path)
        end
        self.settings[setName] = trust_modes

        trust_modes_file:write('-- Modes file for '..self.jobNameShort ..'\nreturn ' .. newSettings:tovstring())
    end

    self.settings[setName] = trust_modes

    self:reloadSettings()

    if setName ~= state.TrustMode.value then
        state.TrustMode:set(setName)
    end

    self:onSettingsChanged():trigger(self:getSettings())
end

function TrustModeSettings:deleteSettings(setName)
    local newSettings = T(self.settings):copy()
    newSettings[setName] = nil

    local file_paths = L{
        'data/modes/'..player.main_job_name_short ..'_'..windower.ffxi.get_player().name..'.lua',
    }
    for file_path in file_paths:it() do
        local trust_modes_file = files.new(file_path)
        if not trust_modes_file:exists() then
            addon_message(207, 'Created trust modes override '..file_path)
        else
            addon_message(207, 'Deleted trust modes for '..setName..' '..file_path)
        end
        self.settings[setName] = nil

        trust_modes_file:write('-- Modes file for '..self.jobNameShort ..'\nreturn ' .. newSettings:tovstring())
    end

    self:reloadSettings()

    state.TrustMode:set('Default')

    self:onSettingsChanged():trigger(self:getSettings())
end

function TrustModeSettings:copySettings()
    local filePath = 'data/modes/'..self.jobNameShort..'_'..windower.ffxi.get_player().name..'.lua'
    local playerSettings = FileIO.new(filePath)
    if not playerSettings:exists() then
        local defaultSettings = FileIO.new('data/modes/'..self.jobNameShort..'.lua')
        playerSettings:write(defaultSettings:read())

        addon_message(207, 'Copied mode settings to '..filePath)
    end
end

function TrustModeSettings:getSettings()
    return self.settings
end

return TrustModeSettings