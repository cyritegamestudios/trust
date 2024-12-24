local FileIO = require('files')
local serializer_util = require('cylibs/util/serializer_util')

local Profile = {}
Profile.__index = Profile

function Profile.new(trustVersion, setName, jobNameShort, modeSettings, jobSettings, weaponSkillSettings, subJobNameShort, subJobSettings)
    local self = setmetatable({}, Profile)

    self.trustVersion = trustVersion
    self.setName = setName
    self.jobNameShort = jobNameShort
    self.subJobNameShort = subJobNameShort
    self.settings = T{
        TrustVersion = trustVersion,
        SetName = setName,
        JobNameShort = jobNameShort,
        ModeSettings = modeSettings,
        JobSettings = jobSettings,
        WeaponSkillSettings = weaponSkillSettings,
    }
    if subJobNameShort and subJobSettings then
        self.settings.SubJobNameShort = subJobNameShort
        self.settings.SubJobSettings = subJobSettings
    end

    return self
end

function Profile:saveToFile()
    local file = FileIO.new(self:getFilePath())
    file:write('-- ===DO NOT MODIFY THIS FILE=== Profile for '..self.jobNameShort ..'\nreturn ' .. serializer_util.serialize(self.settings))
end

function Profile:getFilePath()
    if self.subJobNameShort then
        return 'data/export/profiles/'..self.jobNameShort..'_'..self.subJobNameShort..'_'..windower.ffxi.get_player().name..'_'..self.setName..'.lua'
    else
        return 'data/export/profiles/'..self.jobNameShort..'_'..windower.ffxi.get_player().name..'_'..self.setName..'.lua'
    end
end

function Profile.create(profileName, trustModeSettings, jobSettings, subJobSettings, weaponSkillSettings, shouldCreateJobSettings, shouldCreateSubJobSettings, shouldCreateWeaponSkillSettings)
    local setName = profileName
    if trustModeSettings:getSetNames():contains(setName) then
        addon_system_error("A profile with this name already exists.")
        return
    elseif setName:length() < 2 or setName:find('%s') then
        addon_system_error("Profile names cannot contain spaces and must be at least 2 characters.")
        return
    end

    local trust_modes = {}
    for state_name, _ in pairs(state) do
        if state_name ~= 'TrustMode' then
            trust_modes[state_name:lower()] = state[state_name].value
        end
    end

    if shouldCreateJobSettings then
        trust_modes['maintrustsettingsmode'] = setName
        jobSettings:createSettings(setName)
    end

    if shouldCreateSubJobSettings then
        trust_modes['subtrustsettingsmode'] = setName
        subJobSettings:createSettings(setName)
    end

    if shouldCreateWeaponSkillSettings then
        trust_modes['weaponskillsettingsmode'] = setName
        weaponSkillSettings:createSettings(setName)
    end

    trustModeSettings:saveSettings(setName, trust_modes)

    addon_system_message("Created a new profile "..setName..".")
end

return Profile