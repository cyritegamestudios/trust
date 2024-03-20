---------------------------
-- Utility functions for monsters.
-- @class module
-- @name MonsterUtil

_libs = _libs or {}

require('lists')
local buff_util = require('cylibs/util/buff_util')

local monster_util = {}

_raw = _raw or {}

_libs.monster_util = monster_util

-------
-- Mob names (full, suffix, prefix) that aggro by magic.
local aggroes_by_magic_regex = L{
    '%a+ Elemental',
    '%a+ Flagon',
    '%a+ Pot',
    '%a+ Wamoura',
    '%a+ Weapon'
}

function monster_util.test(target_name)
    for regex in aggroes_by_magic_regex:it() do
        if string.find(target_name, regex) then
            return true
        end
    end
    return false
end

-------
-- Determines if a target is a monster.
-- @tparam number target_id Mob id
-- @treturn Bool True if the target is a monster
function monster_util.is_monster(target_id)
    if target_id == nil then
        return false
    end
    local mob = windower.ffxi.get_mob_by_id(target_id)
    return mob and mob.is_npc and mob.spawn_type == 16
end

-------
-- Determines if a target is a monster.
-- @tparam number target_index Mob index
-- @treturn Bool True if the target is a monster
function monster_util.is_monster_by_index(target_index)
    local target_id = monster_util.id_for_index(target_index)
    if target_id then
        return monster_util.is_monster(target_id)
    end
    return false
end

-------
-- Returns the id for a mob with a given index.
-- @tparam number target_index Mob index
-- @treturn number Target id, or nil if mob is nil
function monster_util.id_for_index(target_index)
    if target_index == nil or target_index == 0 then
        return nil
    end
    local mob = windower.ffxi.get_mob_by_index(target_index)
    if mob then
        return mob.id
    end
    return nil
end

-------
-- Determines if the monster aggroes by magic.
-- @tparam number target_id Mob id
-- @treturn Bool True if the monster aggroes by magic
function monster_util.aggroes_by_magic(target_id)
    if target_id == nil then return false end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if target and target.hpp > 0 and target.status ~= 3 and target.distance:sqrt() < 20 then
        for regex in aggroes_by_magic_regex:it() do
            if string.find(target.name, regex) then
                return true
            end
        end
    end
    return false
end

-------
-- Determines if a mob is unclaimed.
-- @param target_id Mob id
-- @treturn Boolean True if the mob is unclaimed and false otherwise.
function monster_util.is_unclaimed(target_id)
    if target_id == nil then return false end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if target ~= nil and target.claim_id == nil or target.claim_id == 0 then
        return true
    end
    return false
end

-------
-- Determines if a mob is immune to a given debuff.
-- @param target_name Mob name
-- @param debuff_name Debuff name (see res/buffs.lua)
-- @treturn Boolean True if the mob is immune to the given debuff.
function monster_util.immune_to_debuff(target_name, debuff_name)
    if debuff_name == 'sleep' then
        return L{
            'Nostos Qutrub',
        }:contains(target_name) or string.find(target_name, 'Agon (%a+ ?)+')
    end
    return false
end

-------
-- Safely returns the name of a mob.
-- @param target_id Mob id
-- @treturn string Name of the mob, or Unknown if the mob is nil.
function monster_util.monster_name(target_id)
    local mob = windower.ffxi.get_mob_by_id(target_id)
    if mob then
        return mob.name
    end
    return "Unknown"
end

return monster_util