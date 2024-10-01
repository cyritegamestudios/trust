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
function BloodPactRage.new(blood_pact_name)
    local blood_pact = res.job_abilities:with('en', blood_pact_name)
    if blood_pact == nil then
        return nil
    end
    local self = setmetatable(SkillchainAbility.new('job_abilities', blood_pact.id), BloodPactRage)
    return self
end

function BloodPactRage:serialize()
    return "BloodPactRage.new(" .. serializer_util.serialize_args(self:get_name()) .. ")"
end

function BloodPactRage:__eq(otherItem)
    if otherItem.__class == BloodPactRage._class and otherItem:get_ability_id() == self:get_ability_id() then
        return true
    end
    return false
end

return BloodPactRage