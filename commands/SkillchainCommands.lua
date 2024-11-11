local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local localization_util = require('cylibs/util/localization_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')
local skillchain_util = require('cylibs/util/skillchain_util')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SkillchainTrustCommands = setmetatable({}, {__index = TrustCommands })
SkillchainTrustCommands.__index = SkillchainTrustCommands
SkillchainTrustCommands.__class = "SkillchainTrustCommands"

function SkillchainTrustCommands.new(trust, weapon_skill_settings, action_queue)
    local self = setmetatable(TrustCommands.new(), SkillchainTrustCommands)

    self.trust = trust
    self.weapon_skill_settings = weapon_skill_settings
    self.action_queue = action_queue

    local ability_names = L(S(self:get_skillchainer().skillchain_builder:get_abilities():map(function(a) return a:get_name() end)))

    -- General
    self:add_command('clear', self.handle_clear, 'Clears the skillchain and sets all steps to auto')
    self:add_command('reload', self.handle_reload, 'Reloads the skillchain settings from file')
    self:add_command('save', self.handle_save, 'Saves settings changes to file')

    -- AutoSkillchainMode
    self:add_command('auto', self.handle_toggle_auto, 'Automatically make skillchains')
    self:add_command('cleave', self.handle_toggle_cleave, 'Cleave monsters')
    self:add_command('spam', self.handle_toggle_spam, 'Spam the same weapon skill', L{
        PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
    })
    self:add_command('mintp', self.handle_set_mintp, 'Sets the minimum tp for spamming', L{
        ConfigItem.new('tp_amount', 1000, 3000, 50, function(value) return value.." TP" end, "Minimum TP")
    })

    -- AutoAftermathMode
    self:add_command('am', function(_) return self:handle_toggle_mode('AutoAftermathMode', 'Auto', 'Off')  end, 'Prioritize maintaining aftermath on mythic weapons')

    -- Find a skillchain
    self:add_command('set', self.handle_set_step, 'Sets a step of a skillchain', L{
        ConfigItem.new('step_num', 1, 5, 1, function(value) return value end, "Step Number"),
        PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
    })
    self:add_command('next', self.handle_next, 'Finds weapon skills that skillchain with the given weapon skill', L{
        PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
    })
    self:add_command('build', self.handle_build, 'Builds a skillchain with the current equipped weapon', L{
        PickerConfigItem.new('skillchain_property', 'Light Lv.4', skillchain_util.all_skillchain_properties(), nil, "Skillchain Property"),
        ConfigItem.new('num_steps', 2, 6, 1, nil, "Number of Steps"),
    })
    self:add_command('default', self.handle_set_default, 'Sets the default weapon skill to use when no skillchains can be made', L{
        PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
    })

    self:get_skillchainer():on_abilities_changed():addAction(function(_, abilities)
        local ability_names = L(S(abilities:map(function(a) return a:get_name() end)))

        self:add_command('spam', self.handle_toggle_spam, 'Spam the same weapon skill', L{
            PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
        })
        self:add_command('set', self.handle_set_step, 'Sets a step of a skillchain', L{
            ConfigItem.new('step_num', 1, 5, 1, function(value) return value end, "Step Number"),
            PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
        })
        self:add_command('default', self.handle_set_default, 'Sets the default weapon skill to use when no skillchains can be made', L{
            PickerConfigItem.new('weapon_skill_name', ability_names[1], ability_names, nil, "Weapon Skill Name")
        })
    end)

    return self
end

function SkillchainTrustCommands:get_command_name()
    return 'sc'
end

function SkillchainTrustCommands:get_localized_command_name()
    return 'Skillchain'
end

function SkillchainTrustCommands:get_settings()
    return self.weapon_skill_settings:getSettings()[state.WeaponSkillSettingsMode.value]
end

function SkillchainTrustCommands:get_skillchainer()
    return self.trust:role_with_type("skillchainer")
end

function SkillchainTrustCommands:get_spammer()
    return self.trust:role_with_type("spammer")
end

function SkillchainTrustCommands:get_ability(skills, ability_name)
    for combat_skill in skills:it() do
        local ability = combat_skill:get_ability(ability_name)
        if ability then
            return ability
        end
    end
    return nil
end

function SkillchainTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value, force_on)
    local success = true
    local message

    local mode_var = get_state(mode_var_name)
    if not force_on and mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end

    return success, message
end

-- // trust sc clear
function SkillchainTrustCommands:handle_clear()
    local success = true
    local message = "Skillchains will be automatically determined"

    local current_settings = self:get_settings()
    for i = 1, current_settings.Skillchain:length() do
        current_settings.Skillchain[i] = SkillchainAbility.auto()
    end
    self.weapon_skill_settings:saveSettings(true)

    return success, message
end

-- // trust sc reload
function SkillchainTrustCommands:handle_reload()
    local success = true
    local message = "Reloaded skillchain settings from "..self.weapon_skill_settings:getSettingsFilePath()

    self.weapon_skill_settings:loadSettings()

    return success, message
end

-- // trust sc save
function SkillchainTrustCommands:handle_save()
    local success = true
    local message = "Skillchain settings saved to "..self.weapon_skill_settings:getSettingsFilePath()

    self.weapon_skill_settings:saveSettings(true)

    return success, message
end

-- // trust sc auto
function SkillchainTrustCommands:handle_toggle_auto(_)
    local success = true
    local message

    self:handle_toggle_mode('AutoSkillchainMode', 'Auto', 'Off')

    return success, message
end

-- // trust sc spam weapon_skill_name (optional)
function SkillchainTrustCommands:handle_toggle_spam(_, ...)
    local success
    local message

    local ability_name = table.concat({...}, " ") or ""
    ability_name = windower.convert_auto_trans(ability_name)
    if ability_name:empty() then
        self:handle_toggle_mode('AutoSkillchainMode', 'Spam', 'Off')
        return true, message
    end

    local current_settings = self:get_settings()
    for skill in current_settings.Skills:it() do
        if skill:get_ability(ability_name) then
            skill:set_default_ability(ability_name)

            success = true
            message = localization_util.translate(ability_name).." will now be used when spamming"

            self.weapon_skill_settings:saveSettings(true)

            self:handle_toggle_mode('AutoSkillchainMode', 'Spam', 'Off', true)
            break
        end
    end

    if not success then
        message = ability_name.." is not a valid ability name for the current equipped weapons"
    end

    return success, message
end

-- // trust sc cleave
function SkillchainTrustCommands:handle_toggle_cleave(_)
    local success = true
    local message

    self:handle_toggle_mode('AutoSkillchainMode', 'Cleave', 'Off')

    return success, message
end

function SkillchainTrustCommands:handle_set_mintp(_, min_tp)
    local success = false
    local message

    min_tp = tonumber(min_tp or 1000)

    local spammer = self.trust:role_with_type("spammer")
    spammer:set_conditions(L{ MinTacticalPointsCondition.new(min_tp) })

    success = true
    message = "Minimum tp for spamming is now "..min_tp

    return success, message
end

-- // trust sc set step_num ability_name
function SkillchainTrustCommands:handle_set_step(_, step_num, ...)
    local success = false
    local message

    step_num = math.min(step_num, 6)

    local ability_name = table.concat({...}, " ")
    ability_name = windower.convert_auto_trans(ability_name)
    local current_settings = self.weapon_skill_settings:getSettings()[state.WeaponSkillSettingsMode.value]
    if current_settings then
        if ability_name == SkillchainAbility.skip():get_name() then
            current_settings.Skillchain[step_num] = SkillchainAbility.skip()
            success = true
            message = "Step "..step_num.." is now "..SkillchainAbility.skip():get_name()
        elseif ability_name == SkillchainAbility.auto():get_name() then
            current_settings.Skillchain[step_num] = SkillchainAbility.auto()
            success = true
            message = "Step "..step_num.." is now "..SkillchainAbility.auto():get_name()
        else
            for combat_skill in current_settings.Skills:it() do
                local ability = combat_skill:get_ability(ability_name)
                if ability then
                    current_settings.Skillchain[step_num] = ability
                    success = true
                    message = "Step "..step_num.." is now "..localization_util.translate(ability:get_name())
                    self.weapon_skill_settings:saveSettings(true)
                    break
                end
            end
        end
    end
    if not success then
        message = "Unknown ability "..ability_name
    end
    return success, message
end

-- // trust sc next weapon_skill_name
function SkillchainTrustCommands:handle_next(_, ...)
    local success
    local message

    local ability_name = table.concat({...}, " ") or ""
    ability_name = windower.convert_auto_trans(ability_name)

    local weapon_skill = res.weapon_skills:with('en', ability_name)
    if weapon_skill then
        local abilities = res.weapon_skills:with_all('skill', weapon_skill.skill):map(function(weapon_skill) return SkillchainAbility.new('weapon_skills', weapon_skill.id) end):filter(function(ability) return ability ~= nil end)

        local skillchain_builder = SkillchainBuilder.new(abilities)
        skillchain_builder:set_current_step(SkillchainStep.new(1, SkillchainAbility.new('weapon_skills', weapon_skill.id)))

        local next_steps = skillchain_builder:get_next_steps()
        if next_steps:length() > 0 then
            success = true
            message = "Continue with: "
            for step in next_steps:it() do
                message = message..localization_util.translate(step:get_ability():get_name())..' ('..step:get_skillchain()..'), '
            end
        else
            success = false
            message = "Unable to find weapon skills that skillchain with "..weapon_skill_name
        end
    else
        success = false
        message = (weapon_skill_name or 'nil')..' is not a valid weapon skill name'
    end

    return success, message
end

-- // trust sc build property_name num_steps (optional)
function SkillchainTrustCommands:handle_build(_, property_name, num_steps)
    local success
    local message

    local valid_skillchains = skillchain_util.LightSkillchains:union(skillchain_util.DarknessSkillchains)
            :filter(function(s) return not L{ 'Light Lv.4', 'Darkness Lv.4'}:contains(s:get_name()) end)
            :map(function(s) return s:get_name() end)
            :union(S{ 'LightLv4', 'DarknessLv4' })

    if property_name == nil or skillchain_util[property_name] == nil then
        success = false
        message = "Valid skillchain properties are: "..valid_skillchains:tostring()
    else
        num_steps = tonumber(num_steps or 2)

        local skillchainer = self.trust:role_with_type("skillchainer")

        if property_name == 'Light4' then
            property_name = skillchain_util.LightLv4:get_name()
        elseif property_name == 'Darkness4' then
            property_name = skillchain_util.DarknessLv4:get_name()
        end

        local skillchains = skillchainer.skillchain_builder:build(property_name, num_steps)
        if not skillchains or skillchains:length() > 0 then
            success = true
            message = property_name..": "
            for abilities in skillchains:it() do
                message = message..L(abilities:map(function(ability) return localization_util.translate(ability:get_name()) end)):tostring()..' ** '
            end
        else
            success = false
            message = "No skillchain found"
        end
    end

    return success, message
end

-- // trust sc default weapon_skill_name
function SkillchainTrustCommands:handle_set_default(_, ...)
    local success
    local message

    local ability_name = table.concat({...}, " ") or ""
    ability_name = windower.convert_auto_trans(ability_name)
    if ability_name then
        if ability_name == 'clear' then
            return self:handle_clear_default()
        else
            local current_settings = self:get_settings()
            for skill in current_settings.Skills:it() do
                local matches = skill:get_abilities():filter(function(a) return a:get_name() == ability_name end)
                if matches:length() > 0 then
                    skill.defaultWeaponSkillName = ability_name
                    skill.defaultWeaponSkillId = job_util.weapon_skill_id(ability_name)

                    success = true
                    message = localization_util.translate(ability_name).." will now be used for "..localization_util.translate(skill:get_name()).." if no skillchain can be made"

                    self.weapon_skill_settings:saveSettings(true)
                    break
                end
            end
        end
    end

    if not success then
        message = ability_name.." is not a valid weapon skill for the current equipped weapons"
    end

    return success, message
end

-- // trust sc default clear
function SkillchainTrustCommands:handle_clear_default(_)
    local success = true
    local message

    local current_settings = self:get_settings()

    local combat_skill_ids = self.trust:get_party():get_player():get_combat_skill_ids()
    for combat_skill_id in combat_skill_ids:it() do
        for skill in current_settings.Skills:it() do
            if skill:get_id() == combat_skill_id and skill.__type == CombatSkillSettings.__type then
                skill.defaultWeaponSkillName = nil
                skill.defaultWeaponSkillId = nil

                self.weapon_skill_settings:saveSettings(true)
            end
        end
    end

    message = "Default abilities have been cleared for the current equipped weapons."

    return success, message
end

return SkillchainTrustCommands
