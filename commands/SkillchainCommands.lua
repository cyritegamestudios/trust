local localization_util = require('cylibs/util/localization_util')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')
local skillchain_util = require('cylibs/util/skillchain_util')
local localization_util = require('cylibs/util/localization_util')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SkillchainTrustCommands = setmetatable({}, {__index = TrustCommands })
SkillchainTrustCommands.__index = SkillchainTrustCommands
SkillchainTrustCommands.__class = "SkillchainTrustCommands"

function SkillchainTrustCommands.new(trust, weapon_skill_settings, action_queue)
    local self = setmetatable(TrustCommands.new(), SkillchainTrustCommands)

    self.trust = trust
    self.weapon_skill_settings = weapon_skill_settings
    self.action_queue = action_queue

    -- General
    self:add_command('reset', self.handle_reset_skillchain, 'Resets skillchain overrides and automatically determines abilities to use')

    -- AutoSkillchainMode
    self:add_command('auto', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Auto', 'Off')  end, 'Automatically make skillchains')
    self:add_command('cleave', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Cleave', 'Off')  end, 'Cleave monsters')
    self:add_command('spam', self.handle_toggle_spam, 'Spam the same weapon skill, // trust sc spam "ability_name" (optional)')

    -- AutoAftermathMode
    self:add_command('am', function(_) return self:handle_toggle_mode('AutoAftermathMode', 'Auto', 'Off')  end, 'Prioritize maintaining aftermath on mythic weapons')

    -- Find a skillchain
    self:add_command('next', self.handle_next, 'Finds weapon skills that skillchain with the given weapon skill')
    self:add_command('build', self.handle_build, 'Builds a skillchain with the current equipped weapon')

    return self
end

function SkillchainTrustCommands:get_command_name()
    return 'sc'
end

function SkillchainTrustCommands:handle_reset_skillchain()
    local success
    local message

    local current_settings = self.weapon_skill_settings:getSettings()[state.WeaponSkillSettingsMode.value]
    if current_settings then
        success = true
        message = "Skillchains will be automatically determined"

        for i = 1, current_settings.Skillchain:length() do
            current_settings.Skillchain[i] = SkillchainAbility.auto()
        end
        self.weapon_skill_settings:saveSettings(true)
    else
        success = false
        message = "Unable to find skillchain settings"
    end
    return success, message
end

-- // trust sc [auto, spam, cleave, partner, open, close, prefer, strict, am]
function SkillchainTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
    local success = true
    local message

    local mode_var = get_state(mode_var_name)
    if mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end

    return success, message
end

function SkillchainTrustCommands:handle_toggle_spam(_, ability_name)
    if ability_name then
        local success, message = self:handle_set_step(ability_name, 1)
        if success then
            message = localization_util.translate(ability_name).." will now be used when spamming"
            handle_set('AutoSkillchainMode', 'Spam')
        end
        return success, message
    else
        return self:handle_toggle_mode('AutoSkillchainMode', 'Spam', 'Off')
    end
end

function SkillchainTrustCommands:handle_set_step(ability_name, step_num)
    local success = false
    local message

    step_num = math.min(step_num, 6)

    local current_settings = self.weapon_skill_settings:getSettings()[state.WeaponSkillSettingsMode.value]
    if current_settings then
        for combat_skill in current_settings.Skills:it() do
            local ability = combat_skill:get_ability(ability_name)
            if ability then
                current_settings.Skillchain[step_num] = ability
                success = true
                message = "Step "..step_num.." is now "..ability:get_name()
                self.weapon_skill_settings:saveSettings(true)
                break
            end
        end
    end
    if not success then
        message = "Unknown ability "..ability_name
    end
    return success, message
end

-- // trust sc next weapon_skill_name
function SkillchainTrustCommands:handle_next(_, weapon_skill_name)
    local success
    local message

    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
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

-- // trust sc build [liquefaction|scission|reverberation|detontation|induration|impaction|transfixion|compression|fragmentation|fusion|gravitation|distortion|light|darkness] num_steps
function SkillchainTrustCommands:handle_build(_, property_name, num_steps)
    local success
    local message

    if property_name == nil or skillchain_util[property_name] == nil then
        success = false
        message = "Valid skillchain properties are [liquefaction|scission|reverberation|detontation|induration|impaction|transfixion|compression|fragmentation|fusion|gravitation|distortion|light|darkness]"
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

return SkillchainTrustCommands