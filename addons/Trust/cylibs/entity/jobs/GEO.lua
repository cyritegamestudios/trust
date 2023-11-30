---------------------------
-- Job file for Geomancer.
-- @class module
-- @name Geomancer

local Job = require('cylibs/entity/jobs/job')
local Geomancer = setmetatable({}, {__index = Job })
Geomancer.__index = Geomancer

-------
-- Default initializer for a new Geomancer.
-- @treturn GEO A Geomancer
function Geomancer.new()
    local self = setmetatable(Job.new(), Geomancer)

    return self
end

-------
-- Returns the Spell for the cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Cure spell
function Geomancer:get_cure_spell(hp_missing)
    if hp_missing > 600 then
        return Spell.new('Cure IV', L{}, L{})
    elseif hp_missing > 300 then
        return Spell.new('Cure III', L{}, L{})
    else
        return Spell.new('Cure II', L{}, L{})
    end
end

-------
-- Returns the Spell for the aoe cure that should be used to restore the given amount of hp.
-- @tparam number hp_missing Amount of hp missing
-- @treturn Spell Aoe cure spell
function Geomancer:get_aoe_cure_spell(hp_missing)
    return nil
end

-------
-- Returns the spell that removes the given status effect.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn Spell Status removal spell
function Geomancer:get_status_removal_spell(debuff_id)
    return nil
end

return Geomancer