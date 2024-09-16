local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local CreateBattleSetEditor = setmetatable({}, {__index = ConfigEditor })
CreateBattleSetEditor.__index = CreateBattleSetEditor
CreateBattleSetEditor.__type = "CreateBattleSetEditor"

-- Settings keys
CreateBattleSetEditor.SettinsgKeys = {}
CreateBattleSetEditor.SettinsgKeys.SetName = 'set_name'
CreateBattleSetEditor.SettinsgKeys.JobSettings = 'create_job_settings'
CreateBattleSetEditor.SettinsgKeys.WeaponSkillSettings = 'create_weapon_skill_settings'

function CreateBattleSetEditor.new(trustModeSettings, jobSettings, weaponSkillSettings, infoView)
    local newSetSettings = {}

    newSetSettings[CreateBattleSetEditor.SettinsgKeys.SetName] = 'NewProfile'
    newSetSettings[CreateBattleSetEditor.SettinsgKeys.JobSettings] = false
    newSetSettings[CreateBattleSetEditor.SettinsgKeys.WeaponSkillSettings] = false

    local configItems = L{
        TextInputConfigItem.new(CreateBattleSetEditor.SettinsgKeys.SetName, newSetSettings[CreateBattleSetEditor.SettinsgKeys.SetName], 'Profile Name', function(text)
            return true
        end),
        BooleanConfigItem.new(CreateBattleSetEditor.SettinsgKeys.JobSettings, 'Create new job settings'),
        BooleanConfigItem.new(CreateBattleSetEditor.SettinsgKeys.WeaponSkillSettings, 'Create new weapon skill settings'),
    }

    local self = setmetatable(ConfigEditor.new(nil, newSetSettings, configItems, nil, function(_) return true end), CreateBattleSetEditor)

    self.newSetSettings = newSetSettings
    self.trustModeSettings = trustModeSettings
    self.infoView = infoView

    self:setScrollDelta(16)
    self:setShouldRequestFocus(true)

    self:getDisposeBag():add(self:onConfigChanged():addAction(function(newConfigSettings, _)
        local setName = newConfigSettings[CreateBattleSetEditor.SettinsgKeys.SetName]
        if self.trustModeSettings:getSetNames():contains(setName) then
            addon_message(123, "A profile with this name already exists.")
            return
        elseif setName:length() < 2 or setName:find('%s') then
            addon_message(123, "Profile names cannot contain spaces and must be at least 2 characters.")
            return
        end

        local trust_modes = {}
        for state_name, _ in pairs(state) do
            if state_name ~= 'TrustMode' then
                trust_modes[state_name:lower()] = state[state_name].value
            end
        end

        local shouldCreateJobSettings = newConfigSettings[CreateBattleSetEditor.SettinsgKeys.JobSettings]
        if shouldCreateJobSettings then
            trust_modes['maintrustsettingsmode'] = setName
            jobSettings:createSettings(setName)
        end

        local shouldCreateWeaponSkillSettings = newConfigSettings[CreateBattleSetEditor.SettinsgKeys.WeaponSkillSettings]
        if shouldCreateWeaponSkillSettings then
            trust_modes['weaponskillsettingsmode'] = setName
            weaponSkillSettings:createSettings(setName)
        end

        trustModeSettings:saveSettings(setName, trust_modes)
    end), self:onConfigChanged())

    return self
end

return CreateBattleSetEditor