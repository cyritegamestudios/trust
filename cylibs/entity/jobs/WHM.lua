---------------------------
-- Job file for White Mage.
-- @class module
-- @name White Mage

local Job = require('cylibs/entity/jobs/job')
local WhiteMage = setmetatable({}, {__index = Job })
WhiteMage.__index = WhiteMage

local spell_util = require('cylibs/util/spell_util')

-------
-- Default initializer for a new White Mage.
-- @tparam T cure_settings Cure thresholds
-- @tparam string afflatus_mode Afflatus Solace or Afflatus Misery
-- @treturn WHM A White Mage
function WhiteMage.new()
    local self = setmetatable(Job.new('WHM', L{ 'Dispelga', 'Impact' }), WhiteMage)
    return self
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function WhiteMage:get_raise_spell()
    if spell_util.can_cast_spell(spell_util.spell_id('Arise')) then
        return Spell.new('Arise')
    else
        return Buff.new('Raise')
    end
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function WhiteMage:get_aoe_spells()
    return L{ 'Banishga', 'Banishga II', 'Diaga' }
end

return WhiteMage