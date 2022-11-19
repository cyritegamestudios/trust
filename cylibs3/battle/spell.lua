---------------------------
-- Wrapper around a spell.
-- @class module
-- @name Spell

require('tables')
require('lists')
require('logger')

local res = require('resources')

local Spell = {}
Spell.__index = Spell

-------
-- Default initializer for a new spell.
-- @tparam string spell_name Localized name of the spell
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string target Spell target (options: bt, p0...pn)
-- @tparam string consumable_name Name of consumable required to cast this spell (optional)
-- @treturn Spell A spell
function Spell.new(spell_name, job_abilities, job_names, target, consumable)
    local self = setmetatable({
        spell_name = spell_name;
        job_abilities = job_abilities or L{};
        job_names = job_names;
        target = target;
        consumable = consumable;
    }, Spell)
    return self
end

-------
-- Returns the full metadata for the spell.
-- @treturn SpellMetadata metadata (see spells.lua)
function Spell:get_spell()
    return res.spells:with('en', self.spell_name)
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

return Spell