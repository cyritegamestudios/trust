---------------------------
-- Job file for DarkKnight.
-- @class module
-- @name DarkKnight

local Job = require('cylibs/entity/jobs/job')
local DarkKnight = setmetatable({}, {__index = Job })
DarkKnight.__index = DarkKnight

-------
-- Default initializer for a new DarkKnight.
-- @treturn DRK A DarkKnight
function DarkKnight.new()
    local self = setmetatable(Job.new(), DarkKnight)

    return self
end

-------
-- Returns the full metadata for the buff corresponding to an absorb spell.
-- @tparam string spell_name Localized absorb spell name (e.g. Absorb-ACC)
-- @treturn BuffMetadata Buff metadata (see buffs.lua)
function DarkKnight:buff_for_absorb_spell(spell_name)
    if spell_name == 'Absorb-ACC' then
        return res.buffs:with('id', 90)
    else
        return nil
    end
end

return DarkKnight