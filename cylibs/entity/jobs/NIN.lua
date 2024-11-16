---------------------------
-- Job file for Ninja.
-- @class module
-- @name Ninja

local Job = require('cylibs/entity/jobs/job')
local Ninja = setmetatable({}, {__index = Job })
Ninja.__index = Ninja

-------
-- Default initializer for a new Ninja.
-- @treturn NIN A Ninja
function Ninja.new()
    local self = setmetatable(Job.new('NIN'), Ninja)
    return self
end

-------
-- Returns all AOE spells.
-- @treturn list List of AOE spell names
function Ninja:get_aoe_spells()
    return L{}
end

-------
-- Returns whether the player has any copy images.
-- @tparam list player_buff_ids List of active player buffs
-- @treturn boolean True if the player has at least one copy image remaining
function Ninja:has_shadows(player_buff_ids)
    player_buff_ids = L(windower.ffxi.get_player().buffs)
    return buff_util.is_any_buff_active(L{ 66, 444, 445, 446 }, player_buff_ids)
end

-------
-- Returns whether an Utsusemi spell overrides another Utsusemi spell.
-- @tparam number current_spell_id Spell id of current shadows
-- @tparam number new_spell_id Spell id of new shadows
-- @treturn boolean True if the new spell overrides the current spell
function Ninja:should_cancel_shadows(current_spell_id, new_spell_id)
    if current_spell_id == nil then
        return true
    elseif current_spell_id == 338 then
        return false--L{ 339, 340 }:contains(new_spell_id)
    elseif current_spell_id == 339 then
        return L{ 338 }:contains(new_spell_id)
    elseif current_spell_id == 340 then
        return L{ 338, 339 }:contains(new_spell_id)
    else
        return false
    end
end

return Ninja