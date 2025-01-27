---------------------------
-- Wrapper around a buff spell.
-- @class module
-- @name Buff

require('tables')
require('lists')

local serializer_util = require('cylibs/util/serializer_util')

local spell_util = require('cylibs/util/spell_util')

local Spell = require('cylibs/battle/spell')

local Buff = setmetatable({}, {__index = Spell })
Buff.__index = Buff
Buff.__type = "Buff"

-------
-- List of AOE buffs prefixes
local aoe_buff_prefixes = L{
    'Auspice',
    'Boost',
    'Protectra',
    'Shellra',
}
known_spells = windower.ffxi.get_spells()
-------
-- Default initializer for a new buff spell.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string spell_prefix string Prefix for spell name (optional) (see spells.lua)
-- @tparam list conditions List of conditions that must be satisfied to cast the spell (optional)
-- @treturn Buff A buff
function Buff.new(spell_name, job_abilities, job_names, spell_prefix, conditions)
    local spell = res.spells:with('en', spell_name)
    spell = spell_util.highest_spell(spell_name)
    if spell then
        local self = setmetatable(Spell.new(spell.en, job_abilities or L{}, job_names or L{}, nil, conditions, nil), Buff)
        self.original_spell_name = spell_name
        return self
    else
        local self = setmetatable(Spell.new(spell_name, job_abilities or L{}, job_names or L{}, nil, conditions, nil), Buff)
        self.original_spell_name = spell_name
        return self
    end
end

-------
-- Returns whether or not this spell is AOE (e.g. Protectra).
-- @treturn Boolean True if the spell is AOE and false otherwise.
function Buff:is_aoe()
    local spell_name = self:get_spell().en
    return spell_util.is_aoe_spell(spell_name) or #aoe_buff_prefixes:filter(function(buff_prefix) return spell_name:contains(buff_prefix) end) > 0
end

-------
-- Returns whether or not the player knows this spell.
-- @treturn Boolean True if the player knows this spell
function Buff:is_valid()
    return spell_util.knows_spell(self:get_spell().id)
end

function Buff:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition) return conditions_classes_to_serialize:contains(condition.__class)  end)
    return "Buff.new(" .. serializer_util.serialize_args(self.original_spell_name, self.job_abilities, self.job_names, self.spell_prefix, conditions_to_serialize) .. ")"
end

function Buff:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_name() == self:get_name() then
        return true
    end
    return false
end

return Buff
