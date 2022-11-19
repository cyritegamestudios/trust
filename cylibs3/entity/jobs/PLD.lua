---------------------------
-- Job file for Paladin.
-- @class module
-- @name Paladin

local Job = require('cylibs/entity/jobs/job')
local Paladin = setmetatable({}, {__index = Job })
Paladin.__index = Paladin

-------
-- Default initializer for a new Paladin.
-- @treturn PLD A Paladin
function Paladin.new()
    local self = setmetatable(Job.new(), Paladin)
    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function Paladin:get_cure_spell(hp_missing)
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
function Paladin:get_aoe_cure_spell(hp_missing)
    return nil
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @tparam number num_targets Number of targets afflicted with the status effect
-- @treturn Spell Status removal spell
function Paladin:get_status_removal_spell(debuff_id, num_targets)
    return nil
end

return Paladin