---------------------------
-- Wrapper around a physical blood pact.
-- @class module
-- @name BloodPactRage

local res = require('resources')
local serializer_util = require('cylibs/util/serializer_util')

local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local BloodPactRage = setmetatable({}, {__index = SkillchainAbility })
BloodPactRage.__index = BloodPactRage
BloodPactRage.__type = "BloodPactRage"
BloodPactRage.__class = "BloodPactRage"

-------
-- Default initializer for a new physical blood pact.
-- @tparam string blood_pact_name Localized name of the blood pact (see res/job_abilities.lua)
-- @treturn BloodPactRage A blood pact rage
function BloodPactRage.new(blood_pact_name, conditions)
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
    local self = setmetatable(SkillchainAbility.new('job_abilities', blood_pact.id, conditions), BloodPactRage)
    return self
end

function BloodPactRage:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "BloodPactRage.new(" .. serializer_util.serialize_args(self:get_name(), conditions_to_serialize) .. ")"
end

function BloodPactRage:__eq(otherItem)
    if otherItem.__class == BloodPactRage._class and otherItem:get_ability_id() == self:get_ability_id() then
        return true
    end
    return false
end

return BloodPactRage