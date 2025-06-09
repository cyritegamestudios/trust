---------------------------
-- Job file for Paladin.
-- @class module
-- @name Paladin

local cure_util = require('cylibs/util/cure_util')
local StatusRemoval = require('cylibs/battle/healing/status_removal')

local Job = require('cylibs/entity/jobs/job')
local Paladin = setmetatable({}, {__index = Job })
Paladin.__index = Paladin

-------
-- Default initializer for a new Paladin.
-- @tparam T cure_settings Cure thresholds
-- @treturn PLD A Paladin
function Paladin.new(cure_settings)
    local self = setmetatable(Job.new('PLD'), Paladin)
    self.cure_settings = cure_settings
    return self
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function Paladin:get_aoe_spells()
    return L{ 'Banishga' }
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function Paladin:get_status_removal_spell(debuff_id, num_targets)
    local spell_id = cure_util.spell_id_for_debuff_id(debuff_id)
    if spell_id then
        return StatusRemoval.new(res.spells:with('id', spell_id).en, L{}, debuff_id)
    end
    return nil
end

-------
-- Returns the delay between status removals.
-- @treturn number Delay between status removals in seconds
function Paladin:get_status_removal_delay()
    return 5
end

return Paladin