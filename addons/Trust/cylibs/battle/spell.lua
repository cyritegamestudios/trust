---------------------------
-- Wrapper around a spell.
-- @class module
-- @name Spell

require('tables')
require('lists')
require('logger')

local res = require('resources')
local StrategemCountCondition = require('cylibs/conditions/strategem_count')

local Spell = {}
Spell.__index = Spell

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
        job_names = job_names;
        target = target;
        consumable = consumable;
        conditions = conditions or L{};
        -- performance optimization, cache the spell data
        cached_spell_metadata = res.spells:with('en', spell_name);
    }, Spell)

    local strategem_count = self.job_abilities:filter(function(job_ability_name)
        local job_ability = res.job_abilities:with('en', job_ability_name)
        return job_ability.type == 'Scholar'
    end):length()
    if strategem_count > 0 then
        self.conditions:append(StrategemCountCondition.new(strategem_count))
    end
    return self
end

-------
-- Returns the full metadata for the spell.
-- @treturn SpellMetadata metadata (see spells.lua)
function Spell:get_spell()
    return self.cached_spell_metadata or res.spells:with('en', self.spell_name)
end

-------
-- Returns the names of the job abilities that should be used with this spell.
-- @treturn list Localized job ability names
function Spell:get_job_abilities()
    return self.job_abilities
end

-------
-- Returns the list of jobs this spell applies to.
-- @treturn list List of job short names (e.g. BLU, RDM, WAR)
function Spell:get_job_names()
    return self.job_names
end

-------
-- Returns whether or not this spell is AOE (e.g. Protectra).
-- @treturn Boolean True if the spell is AOE and false otherwise.
function Spell:is_aoe()
    return false
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
function Spell:get_target()
    return self.target
end

-------
-- Returns the range of the spell in yalms.
-- @treturn number Range of the spell (e.g. 18, 21, etc.)
function Spell:get_range()
    return 21
end

-------
-- Return the name of the consumable required to cast this spell.
-- @treturn string Name of the consumable (e.g. Shihei), or nil if none is required
function Spell:get_consumable()
    return self.consumable
end

-------
-- Return the conditions to cast the spell.
-- @treturn list List of conditions
function Spell:get_conditions()
    return self.conditions
end

-------
-- Return a description of the spell.
-- @treturn string Description
function Spell:description()
    local result = self.spell_name
    if self.job_names and self.job_names:length() > 0 then
        local job_names = self.job_names:tostring()
        if self.job_names:equals(job_util.all_jobs()) then
            job_names = "All Jobs"
        end
        result = result..' → '..job_names
    end
    return result
end

return Spell