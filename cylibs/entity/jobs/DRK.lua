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
    local self = setmetatable(Job.new('DRK', L{ 'Impact' }), DarkKnight)
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

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function DarkKnight:get_aoe_spells()
    return L{}
end

-------
-- Returns a list of conditions for a spell.
-- @tparam Spell spell The spell
-- @treturn list List of conditions
function DarkKnight:get_conditions_for_spell(spell)
    if L{ 'Drain II', 'Drain III' }:contains(spell:get_spell().en) then
        return spell:get_conditions() + L{NotCondition.new(L{HasBuffCondition.new("Max HP Boost", windower.ffxi.get_player().index)})}
    end
    return spell:get_conditions()
end

return DarkKnight