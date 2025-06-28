---------------------------
-- Wrapper around a job ability
-- @class module
-- @name JobAbility

local ConditionalCondition = require('cylibs/conditions/conditional')
local FlourishAction = require('cylibs/actions/flourish')
local JobAbilityRecastReadyCondition = require('cylibs/conditions/job_ability_recast_ready')
local serializer_util = require('cylibs/util/serializer_util')
local WaltzAction = require('cylibs/actions/waltz')

local JobAbility = {}
JobAbility.__index = JobAbility
JobAbility.__type = "JobAbility"

-------
-- Default initializer for a new job ability.
-- @tparam string job_ability_name Localized name of the job ability
-- @tparam list conditions List of conditions that must be satisfied to use the job ability (optional)
-- @tparam list job_names List of job short names that this spell applies to (optional)
-- @tparam string target Job ability target (options: bt, p0...pn) (optional)
-- @treturn JobAbility A job ability
function JobAbility.new(job_ability_name, conditions, job_names, target)
    local job_ability = res.job_abilities:with('en', job_ability_name)
    if job_ability == nil then
        return nil
    end

    local self = setmetatable({
        job_ability_name = job_ability_name;
        job_ability_id = job_ability.id;
        conditions = conditions or L{};
        job_names = job_names;
        target = target;
        valid_targets = job_ability.targets;
        resource = 'job_abilities';
        enabled = true;
    }, JobAbility)

    if not S{ 'Scholar', 'BloodPactWard' }:contains(self:get_job_ability().type) then
        local recast_ready_condition = JobAbilityRecastReadyCondition.new(job_ability_name)
        recast_ready_condition:set_editable(false)

        self:add_condition(recast_ready_condition)
    end

    if self:get_job_ability().type == 'Scholar' then
        local strategem_condition = StrategemCountCondition.new(1, Condition.Operator.GreaterThanOrEqualTo)
        strategem_condition:set_editable(false)

        self:add_condition(strategem_condition)
    end

    return self
end

-------
-- Returns the name for the job ability (see res/job_abilities.lua).
-- @treturn string Job ability name
function JobAbility:get_job_ability_name()
    return self.job_ability_name
end

-------
-- Returns the id for the job ability (see res/job_abilities.lua).
-- @treturn string Job ability id
function JobAbility:get_job_ability_id()
    return self.job_ability_id
end

-------
-- Returns the id for the job ability (see res/job_abilities.lua).
-- @treturn string Job ability id
function JobAbility:get_ability_id()
    return self:get_job_ability_id()
end

-------
-- Returns the full metadata for the job ability (see res/job_abilities.lua).
-- @treturn table Job ability metadata
function JobAbility:get_job_ability()
    return res.job_abilities[self:get_job_ability_id()]
end

-------
-- Returns the buff/debuff for the spell.
-- @treturn Buff/debuff metadata (see buffs.lua)
function JobAbility:get_status()
    return buff_util.buff_for_job_ability(self:get_ability_id())
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function JobAbility:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for this job ability.
-- @treturn list List of conditions
function JobAbility:get_conditions()
    return self.conditions
end

-------
-- Return the default conditions.
-- @treturn list List of conditions
function JobAbility:get_default_conditions()
    local conditions = L{
        NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'Invisible', 'stun', 'amnesia'}, 1)})
    }
    local job_ability = res.job_abilities[self:get_ability_id()]
    if job_ability then
        local tp_cost = job_ability.tp_cost
        if tp_cost and tp_cost > 0 then
            conditions:append(ConditionalCondition.new(L{ MinTacticalPointsCondition.new(tp_cost), HasBuffCondition.new('Trance') }, Condition.LogicalOperator.Or))
        end
        if job_ability.type == 'Waltz' then
            conditions:append(NotCondition.new(L{ HasBuffCondition.new('Saber Dance') }))
        end
    end
    return conditions
end

-------
-- Returns the target of this job ability.
-- @treturn Mob MobMetadata for the target
function JobAbility:get_target()
    if self.target then
        return windower.ffxi.get_mob_by_target(self.target)
    end
    return nil
end

-------
-- Returns a list of valid targets for this job ability.
-- @treturn list List of valid targets (see res/job_abilities.lua)
function JobAbility:get_valid_targets()
    return S(self.valid_targets)
end

-------
-- Returns the range of the job ability in yalms.
-- @treturn number Range of the spell (e.g. 18, 21, etc.)
function JobAbility:get_range()
    return 17
end

-------
-- Returns whether or not the player knows this spell.
-- @treturn Boolean True if the player knows this spell
function JobAbility:is_valid()
    return job_util.knows_job_ability(job_util.job_ability_id(self:get_job_ability_name()))
end

-------
-- Sets whether the job ability is enabled.
-- @tparam Boolean enabled The new value for enabled
function JobAbility:setEnabled(enabled)
    self.enabled = enabled
end

-------
-- Gets whether the job ability is enabled.
-- @treturn Boolean True if the job ability is enabled
function JobAbility:isEnabled()
    return self.enabled
end

-------
-- Return the Action to use this job ability on a target.
-- @treturn Action Action to cast the spell
function JobAbility:to_action(target_index)
    local job_ability_action
    if string.find(self:get_job_ability_name(), 'Waltz') then
        job_ability_action = WaltzAction.new(self:get_job_ability_name(), target_index or self:get_target())
    elseif string.find(self:get_job_ability_name(), 'Flourish') then
        job_ability_action = FlourishAction.new(self:get_job_ability_name(), target_index or self:get_target())
    else
        local target_index = target_index or self:get_target()
        if S(self.valid_targets) == S{ 'Self' } then
            target_index = windower.ffxi.get_player().index
        end
        job_ability_action = JobAbilityAction.new(0, 0, 0, self:get_job_ability_name(), target_index or self:get_target())
    end
    if job_ability_action then
        job_ability_action.identifier = 'job_ability_'..self:get_name()
    end
    return job_ability_action
end

function JobAbility:get_name()
    return self.job_ability_name
end

function JobAbility:get_localized_name()
    return i18n.resource('job_abilities', 'en', self:get_name())
end

function JobAbility:get_localized_description()
    local buff = buff_util.buff_for_job_ability(self:get_job_ability_id())
    if buff then
        return i18n.resource('buffs', 'en', buff.en)
    end
    return nil
end

function JobAbility:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)

    return "JobAbility.new(" .. serializer_util.serialize_args(self.job_ability_name, conditions_to_serialize, self.job_names, self.target) .. ")"
end

function JobAbility:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_job_ability_id() == self:get_job_ability_id() then
        return true
    end
    return false
end

function JobAbility:copy()
    local conditions = L{}
    for condition in self:get_conditions():it() do
        conditions:append(condition:copy())
    end
    return JobAbility.new(self.job_ability_name, conditions, self.job_names + L{}, self.target)
end

return JobAbility