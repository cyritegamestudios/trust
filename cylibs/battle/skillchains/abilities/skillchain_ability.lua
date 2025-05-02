local HasBuffsCondition = require('cylibs/conditions/has_buffs')
local JobAbilityAction = require('cylibs/actions/job_ability')
local res = require('resources')
local skillchain_util = require('cylibs/util/skillchain_util')
local skills = require('cylibs/res/skills')
local SpellAction = require('cylibs/actions/spell')
local WeaponSkillAction = require('cylibs/actions/weapon_skill')

local SkillchainAbility = {}
SkillchainAbility.__index = SkillchainAbility
SkillchainAbility.__class = "SkillchainAbility"
SkillchainAbility.__type = "SkillchainAbility"

SkillchainAbility.Auto = "Auto"
SkillchainAbility.Skip = "Skip"
SkillchainAbility.None = "None"

-------
-- Default initializer for a SkillchainAbility that represents any ability (or spell) that can participate in a skillchain.
-- @tparam string resource Resource for the ability (e.g. `weapon_skills` for `res/weapon_skills.lua`)
-- @tparam number ability_id Id of the ability within the resource file
-- @tparam list conditions (optional) List of conditions that must be met to use this ability
-- @tparam list job_abilities (optional) List of job abilities to use before this ability
-- @tparam PartyMember party_member (optional) Party member that will use or used this ability
-- @treturn SkillchainAbility A skillchain abilty
function SkillchainAbility.new(resource, ability_id, conditions, job_abilities, party_member)
    if not skills[resource][ability_id] then
        return nil
    end
    local self = setmetatable({
        resource = resource;
        ability_id = ability_id;
        conditions = conditions or L{};
        job_abilities = job_abilities or L{};
        party_member = party_member;
        name = res[resource][ability_id].en;
        skill_id = res[resource][ability_id].skill;
    }, SkillchainAbility)
    return self
end

function SkillchainAbility.skip()
    local self = setmetatable({
        ability_id = SkillchainAbility.Skip;
        name = "Skip";
    }, SkillchainAbility)
    return self
end

function SkillchainAbility.auto()
    local self = setmetatable({
        ability_id = SkillchainAbility.Auto;
        name = "Auto";
        conditions = L{};
    }, SkillchainAbility)
    return self
end

function SkillchainAbility.none()
    local self = setmetatable({
        ability_id = SkillchainAbility.None;
        name = "None";
        conditions = L{};
    }, SkillchainAbility)
    return self
end

function SkillchainAbility:destroy()
end

-------
-- Returns the name of the ability.
-- @treturn string Name of ability (e.g. `Fire VI`, `Catastrophe`)
function SkillchainAbility:get_name()
    return self.name
end

-------
-- Returns the localized name of the ability.
-- @treturn string Localized name of ability (e.g. `Fire VI`, `Catastrophe`)
function SkillchainAbility:get_localized_name()
    if S{ SkillchainAbility.Auto, SkillchainAbility.Skip, SkillchainAbility.None }:contains(self:get_name()) then
        return self:get_name()
    end
    return i18n.resource(self.resource, 'en', self:get_name())
end

-------
-- Returns the id of the ability.
-- @treturn number Id of ability
function SkillchainAbility:get_ability_id()
    return self.ability_id
end

-------
-- Returns the skill id of the ability.
-- @treturn number Skill id of ability
function SkillchainAbility:get_skill_id()
    return self.skill_id
end

-- Returns the buffs required to skillchain with this ability (e.g. `Immanence`)
-- @treturn number Buff id (see res/buffs.lua)
function SkillchainAbility:get_buffs()
    if L{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(self:get_name()) then
        return S{}
    end
    local skill = skills[self.resource][self.ability_id]
    if skill and skill.buffs then
        return S(skill.buffs)
    end
    return S{}
end

-- Returns the list of conditions that must be met to skillchain with this ability.
-- @treturn list List of conditions
function SkillchainAbility:get_conditions()
    local conditions = L{}:extend(self.conditions or L{})
    if self.party_member then
        local buffs = self:get_buffs()
        if buffs:length() > 0 then
            conditions:append(HasBuffsCondition.from_party_member(buffs:map(function(buff_id) return buff_util.buff_name(buff_id) end), 1, self.party_member))
        end
    end
    return conditions
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function SkillchainAbility:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-- Returns the amount of time this ability extends the skillchain window by.
-- @treturn number Delay in seconds
function SkillchainAbility:get_delay()
    local skill = skills[self.resource][self.ability_id]
    if skill then
        return skill.delay or 3
    end
    return 3
end

-- Returns the skillchain properties of this ability (e.g. `Light`, `Fire`, `Water`).
-- @tparam boolean include_aeonic If true, include aeonic properties
-- @treturn list List of skillchain properties (see util/skillchain_util.lua)
function SkillchainAbility:get_skillchain_properties(include_aeonic)
    if L{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(self:get_name()) then
        return L{}
    end
    local skill = skills[self.resource][self.ability_id]
    local properties = L(skill.skillchain)
    if include_aeonic and skill.aeonic then
        properties:append(skill.aeonic)
    end
    return properties:map(function(property_name) return skillchain_util[property_name] end)
end

-- Returns whether this ability has aeonic properties.
-- @treturn boolean True if the skill has aeonic properties
function SkillchainAbility:has_aeonic_properties()
    if L{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(self:get_name()) then
        return false
    end
    local skill = skills[self.resource][self.ability_id]
    return skill and skill.aeonic
end

-- Sets the job abilities to use before this ability.
-- @tparam list job_abilities List of job abilities
function SkillchainAbility:set_job_abilities(job_abilities)
    self.job_abilities = job_abilities
end

-- Returns job abilities to use before this ability.
-- @treturn list List of job abilities
function SkillchainAbility:get_job_abilities()
    return self.job_abilities
end

-- Returns whether this ability is AOE.
-- @treturn boolean True if AOE, false otherwise
function SkillchainAbility:is_aoe()
    local name = self:get_name()
    return spell_util.is_aoe_spell(name)
            or L{ 'Aeolian Edge', 'Cyclone', 'Earth Crusher',
                  'Spinning Scythe', 'Spinning Attack', 'Shockwave',
                  'Circle Blade', 'Fell Cleave', 'Sonic Thrust'
    }:contains(name)
end

-- Returns the action to perform this ability.
-- @tparam number target_index Index of target of the ability
-- @tparam Player player Player
-- @treturn Action The action
function SkillchainAbility:to_action(target_index, player, job_abilities)
    local actions = L{}

    for buff_id in self:get_buffs():it() do
        local job_ability = buff_util.job_ability_for_buff(buff_id)
        if job_ability and job_util.can_use_job_ability(job_ability.en) then
            actions:append(JobAbilityAction.new(0, 0, 0, job_ability.en))
            actions:append(WaitAction.new(0, 0, 0, 2))
            break
        end
    end

    job_abilities = L{}:extend(job_abilities or L{}):extend(self.job_abilities):map(function(job_ability)
        if type(job_ability) == 'string' then
            return JobAbility.new(job_ability)
        end
        return job_ability
    end)
    for job_ability in job_abilities:it() do
        if job_util.can_use_job_ability(job_ability:get_name())
                and Condition.check_conditions(job_ability:get_conditions(), windower.ffxi.get_player().index) then
            local job_ability_action = job_ability:to_action()
            if job_ability_action:can_perform() then
                actions:append(job_ability_action)
            else
                job_ability_action:destroy()
            end
        end
    end

    if self.resource == 'weapon_skills' then
        actions:append(WeaponSkillAction.new(self:get_name(), target_index))
    elseif self.resource == 'job_abilities' then
        local job_ability = res.job_abilities:with('en', self:get_name())
        if job_ability and job_ability.prefix == '/pet' and job_ability.type ~= 'BloodPactRage' then
            actions:append(JobAbilityAction.new(0, 0, 0, self:get_name()))
        else
            actions:append(JobAbilityAction.new(0, 0, 0, self:get_name(), target_index))
        end
    elseif self.resource == 'spells' then
        actions:append(SpellAction.new(0, 0, 0, self:get_ability_id(), target_index, player))
    end

    actions:append(WaitAction.new(0, 0, 0, 3))

    return SequenceAction.new(actions, 'skillchain_ability_sc', false)
end

function SkillchainAbility:copy()
    local conditions = L{}
    for condition in self:get_conditions():it() do
        conditions:append(condition:copy())
    end
    return SkillchainAbility.new(self.resource, self.ability_id, conditions, self.job_abilities, self.party_member)
end

function SkillchainAbility:serialize()
    local name = self:get_name()
    if name == SkillchainAbility.Auto then
        return "SkillchainAbility.auto()"
    elseif name == SkillchainAbility.Skip then
        return "SkillchainAbility.skip()"
    end
    return nil
end

function SkillchainAbility:__eq(otherItem)
    if not otherItem.__class == SkillchainAbility.__class then
        return false
    end
    return otherItem:get_name() == self:get_name()
end

return SkillchainAbility