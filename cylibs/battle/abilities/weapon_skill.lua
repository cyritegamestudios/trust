---------------------------
-- Wrapper around a weapon skill.
-- @class module
-- @name WeaponSkill

local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local res = require('resources')
local serializer_util = require('cylibs/util/serializer_util')

local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local WeaponSkill = setmetatable({}, {__index = SkillchainAbility })
WeaponSkill.__index = WeaponSkill
WeaponSkill.__type = "WeaponSkill"
WeaponSkill.__class = "WeaponSkill"

-------
-- Default initializer for a new weapon skill.
-- @tparam string weapon_skill_name Localized name of the weapon skill (see res/weapon_skills.lua)
-- @tparam list conditions (optional) List of conditions that must be met to use this ability
-- @tparam list job_abilities List of job abilities to use, if any
-- @treturn WeaponSkill A weapon skill
function WeaponSkill.new(weapon_skill_name, conditions, job_abilities)
    conditions = conditions or L{}
    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
    if weapon_skill == nil then
        return nil
    end
    local matches = conditions:filter(function(c)
        return c.__class == MinTacticalPointsCondition.__class
    end)
    if matches:length() == 0 then
        local tp_condition = MinTacticalPointsCondition.new(1000)
        tp_condition:set_editable(false)
        conditions:append(tp_condition)
    end
    local skillchain_ability = SkillchainAbility.new('weapon_skills', weapon_skill.id, conditions, job_abilities)
    if skillchain_ability == nil then
        return nil
    end
    local self = setmetatable(skillchain_ability, WeaponSkill)
    return self
end

-------
-- Returns the config items that will be used when creating the config editor
-- to edit this ability.
-- @treturn list List of ConfigItem
function WeaponSkill:get_config_items(trust)
    local allJobAbilities = (trust and L(trust:get_job():get_job_abilities(function(jobAbilityId)
        return true
    end):map(function(jobAbilityId)
        return res.job_abilities[jobAbilityId].en
    end)) or L{}):sort()

    local configItem = MultiPickerConfigItem.new("job_abilities", self.job_abilities, allJobAbilities, function(jobAbilityNames)
        local summary = localization_util.commas(jobAbilityNames:map(function(jobAbilityName) return i18n.resource('job_abilities', 'en', jobAbilityName) end), 'and')
        if summary:length() == 0 then
            summary = "None"
        end
        return summary
    end, "Job Abilities", nil, function(jobAbilityName)
        return AssetManager.imageItemForJobAbility(jobAbilityName)
    end)
    configItem:setPickerTitle("Job Abilities")
    configItem:setPickerDescription("Choose one or more job abilities to use with this weapon skill.")
    configItem:setNumItemsRequired(0)
    return L{
        configItem,
    }
end

--[[function WeaponSkill:to_action(target_index, _)
    local action = WeaponSkillAction.new(self:get_name(), target_index)
    action.identifier = self.__class..'_'..self:get_name()
    return action
end]]

function WeaponSkill:serialize(exclude_conditions)
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = not exclude_conditions and self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end) or L{}
    return "WeaponSkill.new(" .. serializer_util.serialize_args(self:get_name(), conditions_to_serialize, self.job_abilities) .. ")"
end

function WeaponSkill:is_valid()
    return true
end

function WeaponSkill:copy()
    local conditions = L{}
    for condition in self:get_conditions():it() do
        conditions:append(condition:copy())
    end
    return WeaponSkill.new(self:get_name(), conditions)
end

function WeaponSkill:__eq(otherItem)
    if not L{ SkillchainAbility.__class, WeaponSkill.__class }:contains(otherItem.__class) then
        return false
    end
    return otherItem:get_name() == self:get_name()
end

return WeaponSkill