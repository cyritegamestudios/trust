---------------------------
-- Job file for Red Mage.
-- @class module
-- @name Red Mage

local Job = require('cylibs/entity/jobs/job')
local RedMage = setmetatable({}, {__index = Job })
RedMage.__index = RedMage

-------
-- Default initializer for a new Red Mage.
-- @treturn RDM A Red Mage
function RedMage.new()
    local self = setmetatable(Job.new(), RedMage)
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function RedMage:get_cure_spell(hp_missing)
    if hp_missing > 900 then
        return Spell.new('Cure IV', L{}, L{})
    elseif hp_missing > 600 then
        return Spell.new('Cure III', L{}, L{})
    else
        return nil
    end
end

-------
-- Returns the Spell for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Aoe cure spell
function RedMage:get_aoe_cure_spell(hp_missing)
    return nil
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function RedMage:get_status_removal_spell(debuff_id, num_targets)
    return nil
end

return RedMage