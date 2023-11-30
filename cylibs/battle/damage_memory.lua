---------------------------
-- Tracks the damage a player takes.
-- @class module
-- @name DamageMemory

require('tables')
require('lists')
require('logger')

local DamageMemory = {}
DamageMemory.__index = DamageMemory

-------
-- Default initializer for a new damage memory tracker.
-- @tparam number damage_threshold Only damage exceeding this amount will be recorded
-- @treturn DamageMemory A damage memory tracker
function DamageMemory.new(damage_threshold)
    local self = setmetatable({
        action_events = {};
        damage_threshold = damage_threshold;
        damage_taken_history = {};
    }, DamageMemory)

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function DamageMemory:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    if self.battle_target then
        self.battle_target:destroy()
    end
end

-------
-- Starts tracking damage taken. Note that it is necessary to call this before battle target tp moves will be tracked.
-- Before this object is disposed of, destroy() should be called.
function DamageMemory:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true
end

-------
-- Call when the target changes. Will begin tracking damage taken from tp moves initiated by the new target.
-- @tparam number target_index New target index
function DamageMemory:target_change(target_index)
    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end

    if target_index then
        self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
        self.battle_target:monitor()

        self.monster_tp_move_finish_id = self.battle_target:on_tp_move_finish():addAction(
                function (m, monster_ability_name, target_name, damage)
                    --print(monster_ability_name..' on '..target_name..' for '..damage)
                    if self.battle_target and m:get_mob().index == self.battle_target:get_mob().index then

                    end
                end)
    end
end

-------
-- Resets the damage memory.
function DamageMemory:reset()
    self.damage_taken_history = {}
end

-------
-- Records damage memory.
-- @tparam string monster_ability_name Name of monster ability (see monster_skills.lua)
-- @tparam string target_name Target of damage
-- @tparam number damage Damage taken
function DamageMemory:record_damage(monster_ability_name, target_name, damage)
    local target = windower.ffxi.get_mob_by_name(target_name)
    if damage > self.damage_threshold and party_util.is_party_member(target.id) then
        local current_record = self.damage_taken[target.id]
        if current_record and current_record.damage > damage then
            return
        end

        local damage_record = {}
        damage_record.monster_ability_name = monster_ability_name
        damage_record.damage = damage

        self.damage_taken_history[target.id] = damage_record
    end
end

-------
-- Returns the damage taken for the last tp move to hit the given target.
-- @tparam number target_id Target id
-- @treturn Pair The pair monster_ability_name, damage
function DamageMemory:get_last_damage_taken(target_id)
    local damage_record = self.damage_taken_history[target_id]
    if damage_record then
        return damage_record.monster_ability_name, damage_record.damage
    end
    return nil
end

return DamageMemory