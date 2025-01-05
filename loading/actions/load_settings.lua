local Action = require('cylibs/actions/action')
local LoadSettingsAction = setmetatable({}, { __index = Action })
LoadSettingsAction.__index = LoadSettingsAction

function LoadSettingsAction.new(main_job_name_short, sub_job_name_short)
    local self = setmetatable(Action.new(0, 0, 0), LoadSettingsAction)

    self.main_job_name_short = main_job_name_short
    self.sub_job_name_short = sub_job_name_short

    windower.trust.settings = {}

    return self
end

function LoadSettingsAction:load_main_trust_settings()
    state.MainTrustSettingsMode = M{['description'] = 'Main Trust Settings Mode', 'Default'}

    main_trust_settings = TrustSettingsLoader.new(self.main_job_name_short)
    main_trust_settings:onSettingsChanged():addAction(function(newSettings)
        local oldValue = state.MainTrustSettingsMode.value
        player.trust.main_job_settings = newSettings
        local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Migrations','Version'})
        if not mode_names:equals(state.MainTrustSettingsMode:options()) then
            state.MainTrustSettingsMode:options(T(mode_names):unpack())
        end
        if mode_names:contains(oldValue) then
            state.MainTrustSettingsMode:set(oldValue)
        else
            state.MainTrustSettingsMode:set('Default')
        end
    end)

    player.trust.main_job_settings = main_trust_settings:loadSettings()
end

function LoadSettingsAction:load_sub_trust_settings()
    state.SubTrustSettingsMode = M{['description'] = 'Sub Trust Settings Mode', 'Default'}

    sub_trust_settings = TrustSettingsLoader.new(self.sub_job_name_short)
    sub_trust_settings:onSettingsChanged():addAction(function(newSettings)
        local oldValue = state.SubTrustSettingsMode.value
        player.trust.sub_job_settings = newSettings
        local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Migrations','Version'})
        if not mode_names:equals(state.SubTrustSettingsMode:options()) then
            state.SubTrustSettingsMode:options(T(mode_names):unpack())
        end
        if mode_names:contains(oldValue) then
            state.SubTrustSettingsMode:set(oldValue)
        else
            state.SubTrustSettingsMode:set('Default')
        end
    end)

    player.trust.sub_job_settings = sub_trust_settings:loadSettings()
end

function LoadSettingsAction:load_weapon_skill_settings()
    state.WeaponSkillSettingsMode = M{['description'] = 'Weapon Skill Settings Mode', 'Default'}

    weapon_skill_settings = WeaponSkillSettings.new(self.main_job_name_short)
    weapon_skill_settings:onSettingsChanged():addAction(function(newSettings)
        local oldValue = state.WeaponSkillSettingsMode.value
        player.trust.weapon_skill_settings = newSettings
        local mode_names = list.subtract(L(T(newSettings):keyset()), L{'Migrations','Version'})
        state.WeaponSkillSettingsMode:options(T(mode_names):unpack())
        if mode_names:contains(oldValue) then
            state.WeaponSkillSettingsMode:set(oldValue)
        else
            state.WeaponSkillSettingsMode:set('Default')
        end
    end)

    player.trust.weapon_skill_settings = weapon_skill_settings:loadSettings(true)
end

function LoadSettingsAction:load_settings()
    addon_settings = TrustAddonSettings.new()
    addon_settings:loadSettings()
end

function LoadSettingsAction:perform()
    player.trust = {}

    --local profile = require('cylibs/util/profile')

    --profile.start()

    self:load_settings()
    self:load_main_trust_settings()
    self:load_sub_trust_settings()
    self:load_weapon_skill_settings()

    --profile.stop()

    --profile.report(4)

    self:complete(true)
end

function LoadSettingsAction:gettype()
    return "loadsettingsaction"
end

function LoadSettingsAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function LoadSettingsAction:tostring()
    return "Loading addon settings"
end

return LoadSettingsAction




