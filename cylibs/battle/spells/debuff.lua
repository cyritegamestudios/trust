---------------------------
-- Wrapper around a debuff spell.
-- @class module
-- @name Debuff

require('tables')
require('lists')

local serializer_util = require('cylibs/util/serializer_util')

local Spell = require('cylibs/battle/spell')

local Debuff = setmetatable({}, {__index = Spell })
Debuff.__index = Debuff
Debuff.__type = "Debuff"

-------
-- Default initializer for a new debuff spell.
-- @tparam number buff_id Debuff id (see buffs.lua)
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string spell_prefix string Prefix for spell name (optional) (see spells.lua)
-- @treturn Spell A spell
function Debuff.new(spell_name, job_abilities, job_names, spell_prefix)
    local spell = res.spells:with('en', spell_name)
    spell = spell_util.highest_spell_for_buff_id(spell_util.buff_id_for_spell(spell.id), spell_name)
    if spell then
        local self = setmetatable(Spell.new(spell.en, job_abilities or L{}, job_names), Debuff)
        self.original_spell_name = spell_name
        return self
    else
        return nil
    end
end

function Debuff:serialize()
    return "Debuff.new(" .. serializer_util.serialize_args(self.original_spell_name, self.job_abilities, self.job_names, self.spell_prefix) .. ")"
end

return Debuff