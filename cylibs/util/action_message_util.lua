---------------------------
-- Utility functions for parsing action messages.
-- @class module
-- @name ActionMessageUtil

_libs = _libs or {}

require('lists')

local action_message_util = {}

_raw = _raw or {}

_libs.action_message_util = action_message_util

-------
-- Determines if an action message indicates that a monster has been defeated.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if the given message_id corresponds to a message indicating the monster has been defeated and false otherwise
function action_message_util.is_monster_defeated(message_id)
    if message_id == nil then return false end

    return L{6,20,113,406,605,646}:contains(message_id)
end

-------
-- Determines if an action message indicates that a player has missed an attack, job ability or weapon skill.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if the given message_id corresponds to a message indicating the player has missed an attack
function action_message_util.is_miss_attack_message(message_id)
    if message_id == nil then return false end

    return L{15,16,53,354}:contains(message_id)
end

-------
-- Determines if an action message indicates that a player is taking damage from spikes.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if the given message_id corresponds to a message indicating the player is taking damage from spikes.
function action_message_util.is_spikes_message(message_id)
    if message_id == nil then return false end

    return L{44,132,383}:contains(message_id)
end

-------
-- Determines if an action message indicates that a player has hit an attack, job ability or weapon skill.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if the given message_id corresponds to a message indicating the player has hit an attack
function action_message_util.is_hit_attack_message(message_id)
    if message_id == nil then return false end

    return L{1,67,264,352,353}:contains(message_id)
end

-------
-- Determines if an action message indicates that a monster has gained a buff.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @tparam number param Spell id, weapon skill id, etc (see spells.lua, monster_skills.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating the monster has gained a buff and false otherwise
function action_message_util.is_monster_gain_buff(message_id, param)
    if L{750}:contains(param) then
        return true
    end
    return L{194}:contains(message_id)
end

-------
-- Determines if an action message indicates that a spell has no effect on the target.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating the spell has no effect on the target
function action_message_util.is_spell_no_effect_message(message_id)
    if L{75}:contains(message_id) then
        return true
    end
    return false
end

-------
-- Determines if an action message indicates that a monster has lost a buff.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating the monster has lost a buff and false otherwise
function action_message_util.is_lose_multiple_buffs(message_id)
    if L{231,370,401,404,405,757,792}:contains(message_id) then
        return true
    end
    return false
end

-------
-- Determines if an action message indicates that a monster has lost a buff.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating the monster has lost a buff and false otherwise
function action_message_util.is_monster_lose_buff(message_id)
    if L{168,341,342,343,344,647,806}:contains(message_id) then
        return true
    end
    return false
end

-------
-- Determines if an action message indicates that a target has gained a debuff.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating the target has gained a debuff and false otherwise
function action_message_util.is_gain_debuff_message(message_id)
    return L{2,27,75,236,237,268,269,270,271,272,283,520,754,755}:contains(message_id)
end

-------
-- Determines if an action message indicates that a target has lost a debuff.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating the target has lost a debuff and false otherwise
function action_message_util.is_lose_debuff_message(message_id)
    return L{64,204,206,350,531}:contains(message_id)
end

-------
-- Determines if an action message indicates that a spell has finished casting.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @tparam number param Spell id, weapon skill id, etc (see spells.lua, monster_skills.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating a target has finished casting a spell
function action_message_util.is_spell_finish_message(message_id, param)
    if L{2,7,42,227,228,236,237,309}:contains(message_id) then
        return true
    end
end

-------
-- Determines if an action message indicates that a spell has finished casting.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @tparam number param Spell id, weapon skill id, etc (see spells.lua, monster_skills.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating a target has finished casting a spell
function action_message_util.is_resist_spell_message(message_id, param)
    if L{85}:contains(message_id) then
        return true
    end
end

-------
-- Determines if an action message indicates that a weapon skill has been performed.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating a weapon skill has been performed
function action_message_util.is_weapon_skill_message(message_id)
    return L{ 2, 110, 185, 187, 317, 529, 802 }:contains(message_id)
end

-------
-- Determines if an action message indicates that a skillchain has been performed.
-- @tparam number message_id Action message id (see action_messages.lua)
-- @treturn Bool True if a given message_id corresponds to a message indicating a skillchain has been performed
function action_message_util.is_skillchain_message(message_id)
    return L{ 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 767, 768, 769, 770 }:contains(message_id)
end

function action_message_util.is_skillchainable_action_category(category_string)
    return L{
        'weaponskill_finish',
        'spell_finish',
        'job_ability',
        'mob_tp_finish',
        'avatar_tp_finish',
        'job_ability_unblinkable',
    }:contains(category_string)
end

-------
-- Determines if an action message indicates that an entity has finished an action (e.g. job ability or monster skill)
-- @tparam number category Action category id (see actions.lua)
-- @treturn Bool True if a given category corresponds to a completed job ability or monster skill and false otherwise
function action_message_util.is_finish_tp_move_category(category)
    return L{11}:contains(category)
end

-------
-- Determines if an action message indicates that an entity has finished casting a spell.
-- @tparam number category Action category id (see actions.lua)
-- @treturn Bool True if a given category corresponds to finishing casting a spell.
function action_message_util.is_finish_spell_category(category)
    return L{4}:contains(category)
end

-------
-- Determines if an action message indicates that an entity has finished an action (e.g. weapon skill, spell cast, etc.)
-- @tparam number category Action category id (see actions.lua)
-- @treturn Bool True if a given category corresponds to a category indicating that an action has been finished and false otherwise
function action_message_util.is_finish_action_category(category)
    return L{2,3,4,5,11,13}:contains(category)
end

-------
-- Determines if an action message indicates that spell casting has begun.
-- @tparam number category Action category id (see actions.lua)
-- @treturn Bool True if a given category corresponds to a category indicating that spell casting has begun
function action_message_util.is_casting_begin_category(category)
    return L{8}:contains(category)
end

return action_message_util