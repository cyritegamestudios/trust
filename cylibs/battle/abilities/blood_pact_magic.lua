---------------------------
-- Wrapper around a magical blood pact rage.
-- @class module
-- @name BloodPact

local serializer_util = require('cylibs/util/serializer_util')

local JobAbility = require('cylibs/battle/abilities/job_ability')
local BloodPactMagic = setmetatable({}, {__index = JobAbility })
BloodPactMagic.__index = BloodPactMagic
BloodPactMagic.__type = "BloodPactMagic"

-------
-- Default initializer for a new job ability.
-- @tparam string job_ability_name Localized name of the job ability
-- @tparam list conditions List of conditions that must be satisfied to use the job ability (optional)
-- @tparam list job_names List of job short names that this spell applies to (optional)
-- @tparam string target Job ability target (options: bt, p0...pn) (optional)
-- @treturn JobAbility A job ability
function BloodPactMagic.new(blood_pact_name, conditions)
    local job_ability_meta = JobAbility.new(blood_pact_name, conditions)
    if job_ability_meta == nil then
        return nil
    end
    local self = setmetatable(job_ability_meta, BloodPactMagic)
    return self
end

function BloodPactMagic:get_element()
    return res.job_abilities[self:get_job_ability_id()].element
end

function BloodPactMagic:is_valid()
    return job_util.knows_job_ability(self:get_job_ability_id())
end

function BloodPactMagic:get_mp_cost()
    return 0
end

function BloodPactMagic:set_job_abilities(job_ability_names)
end

function BloodPactMagic:should_use_all_job_abilties()
    return self.use_all_job_abilities
end

function BloodPactMagic:set_should_use_all_job_abilities(use_all_job_abilities)
    self.use_all_job_abilities = use_all_job_abilities
end

function BloodPactMagic:serialize()
    local conditions_classes_to_serialize = L{
        InBattleCondition.__class,
        IdleCondition.__class,
        HasBuffCondition.__class,
        HasBuffsCondition.__class,
        NotCondition.__class
    }
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "BloodPactMagic.new(" .. serializer_util.serialize_args(self.job_ability_name, conditions_to_serialize) .. ")"
end

return BloodPactMagic