local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local TrustSetsConfigEditor = setmetatable({}, {__index = ConfigEditor })
TrustSetsConfigEditor.__index = TrustSetsConfigEditor


function TrustSetsConfigEditor.new(trustSetName, trustModeSettings, trustSettings, subJobTrustSettings, weaponSkillSettings, infoView)
    local currentSettings = {}
    currentSettings['job_set_name'] = state.MainTrustSettingsMode.value
    currentSettings['sub_job_set_name'] = state.SubTrustSettingsMode.value
    currentSettings['weapon_skill_set_name'] = state.WeaponSkillSettingsMode.value
    currentSettings['profile_name'] = trustSetName

    local trustSet = trustModeSettings:getSettings()[trustSetName]

    local configItems = L{
        TextInputConfigItem.new('profile_name', trustSetName, "Profile Name", function(text)
            return true
        end),
        PickerConfigItem.new('job_set_name', trustSet['maintrustsettingsmode'], trustSettings:getSetNames(), nil, "Job Settings"),
        PickerConfigItem.new('sub_job_set_name', trustSet['subtrustsettingsmode'], subJobTrustSettings:getSetNames(), nil, "Sub Job Settings"),
        PickerConfigItem.new('weapon_skill_set_name', trustSet['weaponskillsettingsmode'], weaponSkillSettings:getSetNames(), nil, "Weapon Skill Settings"),
    }

    local self = setmetatable(ConfigEditor.new(nil, currentSettings, configItems, nil, function(_) return true end), TrustSetsConfigEditor)

    self.trustModeSettings = trustModeSettings
    self.infoView = infoView

    self:setScrollDelta(16)
    self:setShouldRequestFocus(true)

    self:getDisposeBag():add(self:onConfigChanged():addAction(function(newConfigSettings, _)
        local trustSet = trustModeSettings:getSettings()[trustSetName]

        trustSet['maintrustsettingsmode'] = newConfigSettings['job_set_name']
        trustSet['subtrustsettingsmode'] = newConfigSettings['sub_job_set_name']
        trustSet['weaponskillsettingsmode'] = newConfigSettings['weapon_skill_set_name']

        local newProfileName = newConfigSettings['profile_name']
        if newProfileName ~= trustSetName then
            trustModeSettings:saveSettings(newProfileName, trustSet, true)
            trustModeSettings:deleteSettings(trustSetName)
        else
            trustModeSettings:saveSettings(trustSetName, trustSet, true)
        end
    end), self:onConfigChanged())

    return self
end

return TrustSetsConfigEditor