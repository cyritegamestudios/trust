---------------------------
-- Wrapper around a spell.
-- @class module
-- @name Spell

require('tables')
require('lists')
require('logger')

local serializer_util = require('cylibs/util/serializer_util')

local res = require('resources')
local StrategemCountCondition = require('cylibs/conditions/strategem_count')

local Spell = {}
Spell.__index = Spell
Spell.__type = "Spell"
Spell.__class = "Spell"

-------
-- Default initializer for a new spell.
-- @tparam string spell_name Localized name of the spell
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string target Spell target (options: bt, p0...pn)
-- @tparam list conditions List of conditions that must be satisfied to cast the spell (optional)
-- @tparam string consumable_name Name of consumable required to cast this spell (optional)
-- @treturn Spell A spell
function Spell.new(spell_name, job_abilities, job_names, target, conditions, consumable)
    local self = setmetatable({
        spell_name = spell_name;
        job_abilities = job_abilities or L{};
        job_names = job_names or L{};
        target = target;
        consumable = consumable;
        conditions = conditions or L{};
        enabled = true;
    }, Spell)

    if S(res.spells:with('en', spell_name)):contains('Party') then
        job_names = job_names or job_util.all_jobs()
    end

    self:add_condition(SpellRecastReadyCondition.new(res.spells:with('en', spell_name).id))

    local strategem_count = self.job_abilities:filter(function(job_ability_name)
        local job_ability = res.job_abilities:with('en', job_ability_name)
        return job_ability.type == 'Scholar'
    end):length()
    if strategem_count > 0 then
        local strategem_condition = (conditions or L{}):filter(function(condition) return condition.__type == StrategemCountCondition.__type end)
        if strategem_condition:length() == 0 then
            self:add_condition(StrategemCountCondition.new(strategem_count))
        end
    end

    return self
end

-------
-- Returns the full metadata for the spell.
-- @treturn SpellMetadata metadata (see spells.lua)
function Spell:get_spell()
    return res.spells:with('en', self.spell_name)
end

-------
-- Returns the full metadata for the spell.
-- @treturn SpellMetadata metadata (see spells.lua)
function Spell:get_ability_id()
    return self:get_spell().id
end

-------
-- Returns the names of the job abilities that should be used with this spell.
-- @treturn list Localized job ability names
function Spell:get_job_abilities()
    return self.job_abilities
end

---
-- Set the job abilities associated with this Spell.
--
-- @tparam list job_ability_names Localized job ability names
--
function Spell:set_job_abilities(job_ability_names)
    self.job_abilities = job_ability_names
end

-------
-- Returns the list of jobs this spell applies to.
-- @treturn list List of job short names (e.g. BLU, RDM, WAR)
function Spell:get_job_names()
    return self.job_names
end

-------
-- Set the job names associated with this Spell.
-- @tparam list job_names A list of jobs this spell applies to (e.g. BLU, RDM, WAR)
function Spell:set_job_names(job_names)
    self.job_names = job_names
end

-------
-- Returns the element id of the spell.
-- @treturn number Element id of the spell (see res/elements.lua)
function Spell:get_element()
    return self:get_spell().element
end

-------
-- Returns whether or not the player knows this spell.
-- @treturn Boolean True if the player knows this spell
function Spell:is_valid()
    return spell_util.knows_spell(self:get_spell().id)
end

-------
-- Returns whether or not this spell is AOE (e.g. Protectra).
-- @treturn Boolean True if the spell is AOE and false otherwise.
function Spell:is_aoe()
    return false
end

-------
-- Returns whether or not this spell only targets self.
-- @treturn Boolean True if the spell only targets self.
function Spell:is_self_target()
    local targets = self:get_spell().targets
    return targets:length() == 1 and targets:contains('Self')
end

-------
-- The spell will not be cast unless at least this number of party members are in range (including the player).
-- @treturn number Number of targets
function Spell:num_targets_required()
    if self:is_aoe() then
        return 2
    else
        return 1
    end
end

-------
-- Returns the spell target.
-- @treturn string Spell target (e.g. bt, p1, p2)
function Spell:get_target(return_mob)
    if return_mob and self.target then
        return windower.ffxi.get_mob_by_target(self.target)
    end
    return self.target
end

-------
-- Returns all valid spell targets.
-- @treturn list Valid spell targets (e.g. bt, p1, p2)
function Spell:get_valid_targets()
    local spell = self:get_spell()
    return L(spell.targets):map(function(target)
        if target == 'Self' then
            return 'me'
        elseif target == 'Party' then
            return L{ 'p0', 'p1', 'p2', 'p3', 'p4', 'p5' }
        elseif target == 'Enemy' then
            return 'bt'
        end
        return nil
    end):compact_map():flatten(true)
end

-------
-- Returns the range of the spell in yalms.
-- @treturn number Range of the spell (e.g. 18, 21, etc.)
function Spell:get_range()
    if self:is_aoe() then
        if self:is_self_target() then
            return math.max(self:get_spell().range, 10)
        end
    end
    return 21
end

-------
-- Return the name of the consumable required to cast this spell.
-- @treturn string Name of the consumable (e.g. Shihei), or nil if none is required
function Spell:get_consumable()
    return self.consumable
end

-------
-- Return the mana points required to cast this spell.
-- @treturn number Mana points
function Spell:get_mp_cost()
    return self:get_spell().mp_cost
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Spell:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Return the conditions to cast the spell.
-- @treturn list List of conditions
function Spell:get_conditions()
    return self.conditions
end

-------
-- Return the Action to cast this spell on a target. Optionally first uses job abilities where conditions are satisfied.
-- @tparam number target_index Target for the spell
-- @treturn Action Action to cast the spell
function Spell:to_action(target_index, player, job_abilities)
    local actions = L{}

    local job_abilities = (job_abilities or self:get_job_abilities()):map(function(job_ability_name)
        local conditions = L{}

        local job_ability = res.job_abilities:with('en', job_ability_name)
        if job_ability.status then
            conditions:append(NotCondition.new(L{ HasBuffCondition.new(res.buffs[job_ability.status].en, player:get_mob().index) }, windower.ffxi.get_player().index))
        end
        return JobAbility.new(job_ability_name, conditions)
    end):filter(function(job_ability)
        return Condition.check_conditions(job_ability:get_conditions(), player:get_mob().index)
    end)

    for job_ability in job_abilities:it() do
        if job_ability.type == 'Scholar' then
            actions:append(StrategemAction.new(job_ability:get_job_ability_name()))
            actions:append(WaitAction.new(0, 0, 0, 1))
        else
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability:get_job_ability_name()))
            actions:append(WaitAction.new(0, 0, 0, 1))
        end
    end

    actions:append(SpellAction.new(0, 0, 0, self:get_spell().id, target_index, player))
    actions:append(WaitAction.new(0, 0, 0, 2))

    return SequenceAction.new(actions, 'spell_'..self:get_spell().en)
end

-------
-- Sets whether the spell is enabled.
-- @tparam Boolean enabled The new value for enabled
function Spell:setEnabled(enabled)
    self.enabled = enabled
end

-------
-- Gets whether the spell is enabled.
-- @treturn Boolean True if the spell is enabled
function Spell:isEnabled()
    return self.enabled
end

-------
-- Return a description of the spell.
-- @treturn string Description
function Spell:description()
    local result = self.spell_name
    if self.job_names and self.job_names:length() > 0 then
        local job_names = "Some Jobs"
        if self.job_names:equals(job_util.all_jobs()) then
            job_names = "All Jobs"
        else
            if self.job_names:length() <= 5 then
                job_names = self.job_names:tostring()
            end
        end
        result = result..' → '..job_names
    end
    return result
end

function Spell:get_name()
    return self.spell_name
end

function Spell:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Spell.new(" .. serializer_util.serialize_args(self.spell_name, self.job_abilities, self.job_names, self.target, conditions_to_serialize, self.consumable) .. ")"
end

function Spell:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_name() == self:get_name() then
        return true
    end
    return false
end

function Spell:__tostring()
    return self:description()
end

return Spell