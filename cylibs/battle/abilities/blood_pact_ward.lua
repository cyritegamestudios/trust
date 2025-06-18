---------------------------
-- Wrapper around a Blood Pact: Ward.
-- @class module
-- @name BloodPact

local serializer_util = require('cylibs/util/serializer_util')
local Summoner = require('cylibs/entity/jobs/SMN')

local JobAbility = require('cylibs/battle/abilities/job_ability')
local BloodPactWard = setmetatable({}, {__index = JobAbility })
BloodPactWard.__index = BloodPactWard
BloodPactWard.__type = "BloodPactWard"

-------
-- Default initializer for a new Blood Pact: Ward.
-- @tparam string job_ability_name Name of the blood pact
-- @tparam list conditions List of conditions
-- @treturn BloodPactWard A blood pact ward
function BloodPactWard.new(blood_pact_name, conditions)
    local self = setmetatable(JobAbility.new(blood_pact_name, conditions), BloodPactWard)
    return self
end

function BloodPactWard:get_element()
    return res.job_abilities[self:get_job_ability_id()].element
end

function BloodPactWard:is_valid()
    return true
end

function BloodPactWard:get_mp_cost()
    return res.job_abilities[self:get_job_ability_id()].mp_cost or 0
end

-------
-- Return the default conditions.
-- @treturn list List of conditions
function BloodPactWard:get_default_conditions()
    local conditions = JobAbility.get_default_conditions(self)
    if self:get_mp_cost() > 0 then
        conditions:append(MinManaPointsCondition.new(self:get_mp_cost()))
    end
    return conditions
end

function BloodPactWard:get_avatar_name()
    local job = Summoner.new()
    return job:get_avatar_name(self:get_name())
end

-------
-- Return the Action to use this blood pact ward on a target.
-- @treturn Action Action to cast the blood pact ward
function BloodPactWard:to_action(target_index, player)
    if target_index ~= windower.ffxi.get_player().index and self:get_valid_targets():contains('Ally') then
        target_index = windower.ffxi.get_player().index
    end
    local actions = L{}

    local avatar = self:get_avatar_name()
    if avatar and pet_util.pet_name() ~= avatar then
        if pet_util.pet_name() ~= nil then
            actions:append(JobAbilityAction.new(0, 0, 0, 'Release'), true)
            actions:append(WaitAction.new(0, 0, 0, 1))
        end
        actions:append(SpellAction.new(0, 0, 0, spell_util.spell_id(avatar), nil, player), true)
    end
    actions:append(WaitAction.new(0, 0, 0, 2))
    actions:append(BloodPactWardAction.new(0, 0, 0, self:get_name(), target_index))
    actions:append(WaitAction.new(0, 0, 0, 2))

    local wardAction = SequenceAction.new(actions, 'blood_pact_ward')
    wardAction.max_duration = 15

    return wardAction
end

function BloodPactWard:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "BloodPactWard.new(" .. serializer_util.serialize_args(self:get_name(), conditions_to_serialize) .. ")"
end

return BloodPactWard