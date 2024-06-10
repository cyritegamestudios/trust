local res = require('resources')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')
local skillchain_util = require('cylibs/util/skillchain_util')
local skills = require('cylibs/res/skills')


local SkillchainBuilder = {}
SkillchainBuilder.__index = SkillchainBuilder
SkillchainBuilder.__class = "SkillchainBuilder"


-------
-- Default initializer for a new skillchain builder.
-- @tparam list abilities List of all possible SkillchainAbility that can be used to build skillchains
function SkillchainBuilder.new(abilities)
    local self = setmetatable({
        abilities = (abilities or L{}):filter(function(ability) return skills[ability.resource][ability.ability_id] ~= nil end);
        conditions = L{};
        cached_steps = L{};
        include_aeonic = false;
    }, SkillchainBuilder)
    return self
end

function SkillchainBuilder:destroy()
end

-------
-- Sets the current step in the skillchain.
-- @tparam SkillchainStep step Skillchain step
function SkillchainBuilder:set_current_step(step)
    self.step = step
    self.cached_steps = nil
end

-- Gets the current skillchain step.
-- @treturn SkillchainStep Current step
function SkillchainBuilder:get_current_step()
    return self.step
end

-------
-- Returns a list of possible next skillchain steps that can be used to continue the skillchain.
-- @treturn table Table mapping ability name to SkillchainAbility
function SkillchainBuilder:get_next_steps()
    if self.cached_steps then
        return self.cached_steps
    end
    local steps = L{}
    if self.step and not self.step:is_closed() then
        local ability_name_to_step = T{}
        local properties = L{}
        if self.step:get_skillchain() then
            properties:append(self.step:get_skillchain())
        else
            properties = self.step:get_ability():get_skillchain_properties(self.include_aeonic)
        end
        for ability in self.abilities:it() do
            if not ability_name_to_step[ability:get_name()] then
                local skillchain = self:get_skillchain_by_properties(properties, ability)
                if skillchain and Condition.check_conditions(self.conditions, skillchain) then
                    local step = SkillchainStep.new(self.step:get_step() + 1, ability, skillchain:get_name())
                    ability_name_to_step[ability:get_name()] = true
                    steps:append(step)
                end
            end
        end
        steps = L(steps:filter(function(step)
            return Condition.check_conditions(self.conditions, skillchain_util[step:get_skillchain()])
        end))
        self:sort_steps(steps, self.step:get_skillchain())

        self.cached_steps = steps
    end
    return steps
end

function SkillchainBuilder:sort_steps(steps, current_skillchain)
    if steps:length() < 2 then
        return steps
    end
    local skillchain_level = (current_skillchain and current_skillchain:get_level() or 1) + 1
    steps:sort(function(step1, step2)
        local level1 = skillchain_util[step1:get_skillchain()]:get_level()
        local level2 = skillchain_util[step2:get_skillchain()]:get_level()

        if level1 < skillchain_level and level2 > skillchain_level then
            return false
        end
        if level1 > skillchain_level and level2 < skillchain_level then
            return true
        end

        local delta_level1 = math.abs(level1 - skillchain_level)
        local delta_level2 = math.abs(level2 - skillchain_level)

        return delta_level1 < delta_level2
    end)
    --print('sorted steps', steps:map(function(step) return step:get_ability():get_name()..', ('..step:get_skillchain()..')'  end))
    return steps
end

-------
-- Sets the list of abilities that should be used to calculate skillchain steps.
-- @tparam list abilities List of SkillchainAbility
function SkillchainBuilder:set_abilities(abilities)
    self.abilities = abilities
end

-------
-- Returns the subset of abilities with the given skillchain property.
-- @tparam string skillchain_property Skillchain property (e.g. Fragmentation, Scission)
-- @treturn list List of SkillchainAbility with a given skillchain property
function SkillchainBuilder:get_abilities(skillchain_property)
    return self.abilities:filter(function(ability) return ability:get_skillchain_properties(self.include_aeonic):contains(skillchain_property) end):compact_map()
end

-------
-- Adds a condition that will be checked against each potential skillchain ability.
-- @tparam Condition condition Condition to add
function SkillchainBuilder:add_condition(condition)
    if not self.conditions:contains(condition) then
        self.conditions:append(condition)
    end
end

function SkillchainBuilder:remove_all_conditions()
    self.conditions = L{}
end

-- TODO: combine this with reduce_skillchain?

-------
-- Returns the first skillchain formed by performing two abilities in sequence, if any.
-- @tparam SkillchainAbility ability1 First ability
-- @tparam SkillchainAbility ability2 Second ability
-- @treturn Skillchain The skillchain formed, or nil if none
function SkillchainBuilder:get_skillchain(ability1, ability2)
    for property1 in ability1:get_skillchain_properties(self.include_aeonic):it() do
        for property2 in ability2:get_skillchain_properties(self.include_aeonic):it() do
            if skillchain_util[property1:get_name()][property2:get_name()] then
                return skillchain_util[property1:get_name()][property2:get_name()]
            end
        end
    end
    return nil
end

-------
-- Returns the first skillchain formed by performing an ability after a list of skillchain properties.
-- @tparam list properties List of Skillchain (e.g. skillchain_util.Light, skillchain_util.Fragmentation)
-- @tparam SkillchainAbility ability2 The skillchain ability
-- @treturn Skillchain The skillchain formed, or nil if none
function SkillchainBuilder:get_skillchain_by_properties(properties, ability2)
    for property1 in properties:it() do
        for property2 in ability2:get_skillchain_properties(self.include_aeonic):it() do
            if skillchain_util[property1:get_name()][property2:get_name()] then
                return skillchain_util[property1:get_name()][property2:get_name()]
            end
        end
    end
    return nil
end

-------
-- Returns the skillchain made by performing a list of abilities in sequence.
-- @tparam list abilities list of SkillchainAbility
-- @treturn Skillchain The skillchain made by chaining the abilities, or nil of no skillchain is made
function SkillchainBuilder:reduce_skillchain(abilities)
    if abilities:length() < 2 then
        return nil
    end
    local stack = L{}:merge(abilities)

    local ability1 = stack:remove(1)
    local ability2 = stack:remove(1)

    local skillchain = self:get_skillchain(ability1, ability2)

    while stack:length() > 0 do
        local ability = stack:remove(1)

        skillchain = self:get_skillchain_by_properties(L{ skillchain }, ability)
        if skillchain == nil then
            return nil
        end
    end
    return skillchain
end

-- Returns all combinations of skillchain properties that can make the given skillchain.
-- @tparam Skillchain skillchain Skillchain (see util/skillchain_util.lua)
-- @tparam number num_steps Number of steps in the skillchain
-- @treturn list List of list of skillchain properties (e.g. [[Transifxion, Scission], [Fragmentation, Distortion]] for Distortion)
function SkillchainBuilder:get_skillchain_properties(skillchain, num_steps)
    local result = L{}

    local stack = L{}:merge(skillchain_util.skillchain[skillchain:get_name()])
    while not stack:empty() do
        local skillchain = stack:remove(1)
        result:append(skillchain)
        if skillchain[1]:get_level() > 1 and skillchain:length() <= 6 then
            local suffix = L{}:merge(skillchain):slice(2)
            for sub_skillchain in (skillchain_util.skillchain[skillchain[1]:get_name()] or L{}):it() do
                stack:append(sub_skillchain:merge(suffix))
            end
        end
    end
    result = result:filter(function(skillchain) return skillchain:length() == num_steps  end)

    return result
end

-- Builds a skillchain with the given property and number of steps.
-- @tparam string property_name Skillchain property name (e.g. Fragmentation, see util/skillchain_util.lua)
-- @tparam number num_steps Number of steps in the skillchain
-- @treturn list List of list of abilities that can be chained to make the desired skillchain
function SkillchainBuilder:build(property_name, num_steps)
    if property_name == nil then
        return L{}
    end

    local skillchain = skillchain_util[property_name]
    local skillchain_combos = self:get_skillchain_properties(skillchain, num_steps)
    --for combo in skillchain_combos:it() do
    --    print(combo:map(function(p) return p:get_name()  end))
   -- end

    -- Second, replace each skillchain property with a list of abilities with that property
    skillchain_combos = skillchain_combos:map(function(combo)
        local result = L{}
        for property in combo:it() do
            --print(property:get_name(), self:get_abilities(property):map(function(a) return a:get_name()  end))
            result:append(self:get_abilities(property):map(function(a) return a  end))
        end
        return result
    end)

    local results = L{}

    -- Third, create all possible combinations of these abilities
    for combo in skillchain_combos:it() do
        local temp = list.combos(combo)
        if temp:length() > 0 then
            results:append(temp)
        end
    end

    -- Fourth, filter by abilities that make the desired skillchain
    results = results:map(function(result)
        return result:filter(function(abilities)
            --print('abilities', abilities:map(function(a) return a:get_name()  end))
            local final_skillchain = self:reduce_skillchain(abilities)
            if final_skillchain == nil then
                return false
            end
            --print(final_skillchain:get_name(), skillchain:get_name())
            return final_skillchain:get_name() == skillchain:get_name()
        end)
    end)
    results = results:flatten(false)

    return results
end

function SkillchainBuilder:has_ability(ability_name)
    for ability in self.abilities:it() do
        if ability:get_name() == ability_name then
            return true
        end
    end
    return false
end

return SkillchainBuilder