---------------------------
-- Utility functions for monsters.
-- @class module
-- @name MonsterUtil

_libs = _libs or {}

require('lists')

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

return monster_util