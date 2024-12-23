local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local Profile = require('ui/settings/profiles/Profile')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local ProfileCommands = setmetatable({}, {__index = TrustCommands })
ProfileCommands.__index = ProfileCommands
ProfileCommands.__class = "ProfileCommands"

function ProfileCommands.new(jobSettings, subJobSettings, trustModeSettings, weaponSkillSettings)
    local self = setmetatable(TrustCommands.new(), ProfileCommands)

    self.jobSettings = jobSettings
    self.subJobSettings = subJobSettings
    self.trustModeSettings = trustModeSettings
    self.weaponSkillSettings = weaponSkillSettings

    self:add_command('default', self.handle_list_profiles, 'Lists all profiles')
    self:add_command('create', self.handle_create_profile, 'Creates a new profile', L{
        PickerConfigItem.new('profile_name', state.TrustMode.value, L{ state.TrustMode.value }, nil, "Profile Name"),
    })

    return self
end

function ProfileCommands:get_command_name()
    return 'profile'
end

-- // trust profile
function ProfileCommands:handle_list_profiles()
    local success = true
    local message = localization_util.commas(L(state.TrustMode:options()), 'and')

    return success, message
end

-- // trust profile create profile_name
function ProfileCommands:handle_create_profile(_, profile_name)
    local success
    local message

    if profile_name and profile_name:length() > 3 then
        success = true
        Profile.create(profile_name, self.trustModeSettings, self.jobSettings, self.subJobSettings, self.weaponSkillSettings, true, true, true)
    else
        success = false
        message = "Invalid profile name "..(profile_name or 'nil')
    end

    return success, message
end

return ProfileCommands