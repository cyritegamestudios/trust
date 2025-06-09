---------------------------
-- Job file for Red Mage.
-- @class module
-- @name RedMage

local StatusRemoval = require('cylibs/battle/healing/status_removal')

local Job = require('cylibs/entity/jobs/job')
local RedMage = setmetatable({}, {__index = Job })
RedMage.__index = RedMage

local cure_util = require('cylibs/util/cure_util')

-------
-- Default initializer for a new Red Mage.
-- @tparam T cure_settings Cure thresholds
-- @treturn RDM A Red Mage
function RedMage.new(cure_settings)
    local self = setmetatable(Job.new('RDM', L{ 'Dispelga', 'Impact' }), RedMage)
    self:set_cure_settings(cure_settings)
    return self
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function RedMage:get_status_removal_spell(debuff_id, num_targets)
    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        return StatusRemoval.new(res.spells:with('id', spell_id).en, L{}, debuff_id)
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function RedMage:get_status_removal_delay()
    return 5
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

-------
-- Sets the cure settings.
-- @tparam T cure_settings Cure settings
function RedMage:set_cure_settings(cure_settings)
    self.cure_settings = cure_settings
end

return RedMage