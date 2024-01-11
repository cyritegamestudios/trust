local localization_util = require('cylibs/util/localization_util')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local SkillchainTrustCommands = setmetatable({}, {__index = TrustCommands })
SkillchainTrustCommands.__index = SkillchainTrustCommands
SkillchainTrustCommands.__class = "SkillchainTrustCommands"

function SkillchainTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), SkillchainTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    -- AutoSkillchainMode
    self:add_command('auto', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Auto', 'Off')  end, 'Automatically make skillchains')
    self:add_command('spam', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Spam', 'Off')  end, 'Spam the same weapon skill')
    self:add_command('cleave', function(_) return self:handle_toggle_mode('AutoSkillchainMode', 'Cleave', 'Off')  end, 'Cleave monsters')

    -- SkillchainPartnerMode
    self:add_command('partner', function(_) return self:handle_toggle_mode('SkillchainPartnerMode', 'Auto', 'Off')  end, 'Make skillchains with party members')
    self:add_command('open', function(_) return self:handle_toggle_mode('SkillchainPartnerMode', 'Open', 'Off')  end, 'Only open skillchains')
    self:add_command('close', function(_) return self:handle_toggle_mode('SkillchainPartnerMode', 'Close', 'Off')  end, 'Only close skillchains')

    -- SkillchainPriorityMode
    self:add_command('prefer', function(_) return self:handle_toggle_mode('SkillchainPriorityMode', 'Prefer', 'Off')  end, 'Prioritize using weapon skills in preferws')
    self:add_command('strict', function(_) return self:handle_toggle_mode('SkillchainPriorityMode', 'Strict', 'Off')  end, 'Only use weapon skills in preferws')

    -- AutoAftermathMode
    self:add_command('am', function(_) return self:handle_toggle_mode('AutoAftermathMode', 'Auto', 'Off')  end, 'Prioritize maintaining aftermath on mythic weapons')

    -- Find a skillchain
    self:add_command('find', self.handle_find, 'Finds weapon skills that skillchain with the given weapon skill')

    return self
end

function SkillchainTrustCommands:get_command_name()
    return 'sc'
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

-- // trust sc find weapon_skill_name
function SkillchainTrustCommands:handle_find(_, weapon_skill_name)
    local success
    local message

    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
    if weapon_skill then
        local abilities = res.weapon_skills:with_all('skill', weapon_skill.skill):map(function(weapon_skill) return SkillchainAbility.new('weapon_skills', weapon_skill.id) end):filter(function(ability) return ability ~= nil end)

        local skillchain_builder = SkillchainBuilder.new(abilities)
        skillchain_builder:set_step(SkillchainStep.new(1, SkillchainAbility.new('weapon_skills', weapon_skill.id)))

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

return SkillchainTrustCommands