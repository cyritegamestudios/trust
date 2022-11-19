---------------------------
-- Wrapper around a buff spell.
-- @class module
-- @name Buff

require('tables')
require('lists')

local Spell = require('cylibs/battle/spell')

local Buff = setmetatable({}, {__index = Spell })
Buff.__index = Buff

-------
-- List of AOE buffs prefixes
local aoe_buff_prefixes = L{
    'Protectra',
    'Shellra',
    'Auspice',
    'Boost',
    'Bar'
}

-------
-- Default initializer for a new buff spell.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string spell_prefix string Prefix for spell name (optional) (see spells.lua)
-- @treturn Spell A spell
--function Buff.new(buff_id, job_abilities, job_names, spell_prefix)
--    local spell = spell_util.highest_spell_for_buff_id(buff_id, spell_prefix)
--    local self = setmetatable(Spell.new(spell.en, job_abilities or L{}, job_names, target), Buff)
--    return self
--end

function Buff.new(spell_name, job_abilities, job_names, spell_prefix)
    local spell = res.spells:with('name', spell_name)
    spell = spell_util.highest_spell_for_buff_id(spell_util.buff_id_for_spell(spell.id), spell_name)
    if spell then
        local self = setmetatable(Spell.new(spell.en, job_abilities or L{}, job_names), Buff)
        return self
    else
        return nil
    end
end

-------
-- Returns whether or not this spell is AOE (e.g. Protectra).
-- @treturn Boolean True if the spell is AOE and false otherwise.
function Buff:is_aoe()
    return #aoe_buff_prefixes:filter(function(buff_prefix) return self:get_spell().en:contains(buff_prefix)  end) > 0
end

return Buff