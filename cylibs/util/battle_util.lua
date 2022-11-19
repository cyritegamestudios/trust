---------------------------
-- Utility functions for battle.
-- @class module
-- @name BattleUtil

_libs = _libs or {}

require('lists')

local packets = require('packets')

local battle_util = {}

_raw = _raw or {}

_libs.battle_util = battle_util

-------
-- Determines if the given target exists and is not dead.
-- @tparam number target_id Mob id
-- @treturn Bool True if the target is valid and false otherwise
function battle_util.is_valid_target(target_id)
    if target_id == nil then return false end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if target and target.hpp > 0 then
        return true
    end
    return false
end

-------
-- Determines if the given target exists and is not dead.
-- @tparam number target_id Mob id
-- @treturn Bool True if the target is valid and false otherwise
function battle_util.is_valid_monster_target(target_id)
    if target_id == nil then return false end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if target and target.hpp > 0 and target.valid_target and target.spawn_type == 16 then
        return true
    end
    return false
end

-------
-- Switches the player's target and engages the given mob. Note that this function sends an action (0x01A) packet.
-- @tparam number target_index Mob index
function battle_util.target_mob(target_index, engage)
    local mob = windower.ffxi.get_mob_by_index(target_index)

    if engage == nil or engage then
        local p = packets.new('outgoing', 0x01A)

        p['Target'] = mob.id
        p['Target Index'] = mob.index
        p['Category'] = 0x0F -- Target
        p['Param'] = 0
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    else
        local p = packets.new('outgoing', 0x016)

        p['Target Index'] = mob.index

        packets.inject(p)
    end
end

-------
-- Returns whether a mob's is targeting a target.
-- @tparam number mob_index Mob index
-- @tparam number target_index Target index
-- @treturn Bool True if the mob's target matches the given target, false otherwise.
function battle_util.is_mob_target(mob_index, target_index)
    local target = windower.ffxi.get_mob_by_index(mob_index)
    if target and target.target_index == target_index then
        return true
    end
    return false
end

return battle_util