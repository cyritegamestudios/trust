---------------------------
-- Wrapper around a physical blood pact.
-- @class module
-- @name BloodPactRage

local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local res = require('resources')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local BloodPactRage = setmetatable({}, {__index = SkillchainAbility })
BloodPactRage.__index = BloodPactRage
BloodPactRage.__type = "BloodPactRage"
BloodPactRage.__class = "BloodPactRage"

-------
-- Default initializer for a new physical blood pact.
-- @tparam string blood_pact_name Localized name of the blood pact (see res/job_abilities.lua)
-- @tparam list conditions (optional) List of conditions that must be met to use this ability
-- @tparam list job_abilities List of job abilities to use, if any
-- @treturn BloodPactRage A blood pact rage
function BloodPactRage.new(blood_pact_name, conditions, job_abilities)
    conditions = conditions or L{}
    local blood_pact = res.job_abilities:with('en', blood_pact_name)
    if blood_pact == nil then
        return nil
    end
    local matches = conditions:filter(function(c)
        return c.__class == JobAbilityRecastReadyCondition.__class
    end)
    if matches:length() == 0 then
        conditions:append(JobAbilityRecastReadyCondition.new(blood_pact.en))
    end
    local self = setmetatable(SkillchainAbility.new('job_abilities', blood_pact.id, conditions, job_abilities), BloodPactRage)
    return self
end

-------
-- Returns the config items that will be used when creating the config editor
-- to edit this ability.
-- @treturn list List of ConfigItem
function BloodPactRage:get_config_items(trust)
    local allJobAbilities = (trust and L(trust:get_job():get_job_abilities(function(job_ability_id)
        return not L{'BloodPactRage', 'BloodPactWard'}:contains(res.job_abilities[job_ability_id].type)
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
    configItem:setPickerDescription("Choose one or more job abilities to use with this blood pact.")
    configItem:setNumItemsRequired(0)
    return L{
        configItem,
    }
end

function BloodPactRage:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "BloodPactRage.new(" .. serializer_util.serialize_args(self:get_name(), conditions_to_serialize, self.job_abilities) .. ")"
end

function BloodPactRage:__eq(otherItem)
    if otherItem.__class == BloodPactRage._class and otherItem:get_ability_id() == self:get_ability_id() then
        return true
    end
    return false
end

return BloodPactRage