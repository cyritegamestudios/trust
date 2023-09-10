---------------------------
-- Wrapper around a refresh spell.
-- @class module
-- @name Refresh

require('tables')
require('lists')

local Spell = require('cylibs/battle/spell')

local res = require('resources')

local Refresh = setmetatable({}, {__index = Spell })
Refresh.__index = Refresh

-------
-- Default initializer for a new refresh spell.
-- @tparam string spell_name Localized name of the spell
-- @tparam list job_abilities List of job abilities to use, if any
-- @tparam list job_names List of job short names that this spell applies to
-- @tparam string target Spell target (options: bt, p0...pn)
-- @treturn Spell A spell
function Refresh.new(job_abilities, job_names, target)
    local spell = spell_util.highest_spell_for_buff_id(buff_util.buff_id('Refresh'))

    local self = setmetatable(Spell.new(spell.en, job_abilities, job_names, target), Refresh)
    return self
end

return Refresh