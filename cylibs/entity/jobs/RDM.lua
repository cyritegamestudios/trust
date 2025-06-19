---------------------------
-- Job file for Red Mage.
-- @class module
-- @name RedMage

local Job = require('cylibs/entity/jobs/job')
local RedMage = setmetatable({}, {__index = Job })
RedMage.__index = RedMage

-------
-- Default initializer for a new Red Mage.
-- @tparam T cure_settings Cure thresholds
-- @treturn RDM A Red Mage
function RedMage.new()
    local self = setmetatable(Job.new('RDM', L{ 'Dispelga', 'Impact' }), RedMage)
    return self
end

-------
-- Returns the spell that can raise a party member.
-- @treturn Spell Raise spell
function RedMage:get_raise_spell()
    return Buff.new('Raise')
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function RedMage:get_aoe_spells()
    return L{ 'Diaga' }
end

return RedMage