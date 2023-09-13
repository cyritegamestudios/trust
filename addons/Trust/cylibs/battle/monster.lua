---------------------------
-- Wrapper around monster metadata with additional functionality.
-- @class module
-- @name Monster

require('tables')
require('lists')
require('logger')

local Event = require('cylibs/events/Luvent')
local res = require('resources')
local action_message_util = require('cylibs/util/action_message_util')
local buff_util = require('cylibs/util/buff_util')
local monster_abilities_ext = require('cylibs/res/monster_abilities')
local spell_util = require('cylibs/util/spell_util')

local Monster = setmetatable({}, {__index = Trust })
Monster.__index = Monster

-- Event called when the monster's target changes.
function Monster:on_target_change()
    return self.target_change
end

-- Event called when the monster finishes a tp move.
function Monster:on_tp_move_finish()
    return self.tp_move_finish
end

-- Event called when the monster gains a buff.
function Monster:on_gain_buff()
    return self.gain_buff
end

-- Event called when the monster gains a debuff.
function Monster:on_gain_debuff()
    return self.gain_debuff
end

function Monster:on_spell_resisted()
    return self.spell_resisted
end

-- Event called when the monster starts casting a spell.
function Monster:on_spell_begin()
    return self.spell_begin
end

-- Event called when a monster's spell finishes casting.
function Monster:on_spell_finish()
    return self.spell_finish
end

-------
-- Default initializer for a new monster.
-- @tparam number mob_id Mob id
-- @treturn Monster A monster
function Monster.new(mob_id)
    local self = setmetatable({
        action_events = {};
        mob_id = mob_id;
        current_target = nil;
        debuff_ids = S{};
    }, Monster)

    self.target_change = Event.newEvent()
    self.tp_move_finish = Event.newEvent()
    self.gain_buff = Event.newEvent()
    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()
    self.spell_resisted = Event.newEvent()
    self.spell_begin = Event.newEvent()
    self.spell_finish = Event.newEvent()

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Monster:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.target_change:removeAllActions()
    self.tp_move_finish:removeAllActions()
    self.gain_buff:removeAllActions()
    self.gain_debuff:removeAllActions()
    self.lose_debuff:removeAllActions()
    self.spell_resisted:removeAllActions()
    self.spell_begin:removeAllActions()
    self.spell_finish:removeAllActions()
end

-------
-- Starts tracking the monster's actions. Note that it is necessary to call this before functions like get_current_target().
-- Before this object is disposed of, stop_tracking() should be called.
function Monster:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.action_events.action = windower.register_event('action', function(act)
        if act.actor_id == self.mob_id then
            self:handle_action_by_monster(act)
        else
            self:handle_action_on_monster(act)
        end
    end)
end

function Monster:handle_action_by_monster(act)
    -- Mighty guard is category 11 and param 2667
    if action_message_util.is_finish_tp_move_category(act.category) then
        for _, target in pairs(act.targets) do
            local action = target.actions[1]
            if action then
                -- ${actor} uses ${weapon_skill}.${lb}${target} takes ${number} points of damage.
                if action.message == 185 then
                    local monster_ability_name = res.monster_abilities:with('id', act.param).en
                    self:on_tp_move_finish():trigger(self, monster_ability_name, windower.ffxi.get_mob_by_id(target.id).name, action.param)
                end
            end
        end
    end

    local target = windower.ffxi.get_mob_by_id(act.targets[1].id)
    if target.id and target.id ~= self.mob_id then
        -- I think mighty guard is going into this case
        if self.current_target == nil or target.id ~= self.current_target.id then
            self:on_target_change():trigger(self, target.index)
        end
        self.current_target = target
    end

    if action_message_util.is_finish_action_category(act.category) then
        local action = act.targets[1].actions[1]
        if action_message_util.is_monster_gain_buff(action.message, action.param) then
            self:on_gain_buff():trigger(self, target.index, action.param)
        elseif action_message_util.is_spell_finish_message(action.message, act.param) then
            self:on_spell_finish():trigger(self, target.index, act.param)
        elseif monster_abilities_ext:with('id', action.param) then
            local buff = res.buffs:with('id', action.param)
            if buff then
                self:on_gain_buff():trigger(self, target.index, action.param)
            end
        end
    end
end

function Monster:handle_action_on_monster(act)
    for _, target in pairs(act.targets) do
        if target.id == self.mob_id then
            local action = target.actions[1]
            if action then
                if action_message_util.is_gain_debuff_message(action.message) then
                    local debuff = buff_util.debuff_for_spell(act.param)
                    if debuff then
                        self.debuff_ids:add(debuff.id)
                        self:on_gain_debuff():trigger(self, debuff.en)
                    end
                elseif action_message_util.is_spikes_message(action.message) then
                    -- Note: since we don't know the source of the spikes, we are just using the id for Ice Spikes
                    self:on_gain_buff():trigger(self, target.index, 35)
                -- resist: 85, 284 (AOE)
                -- completely resist: 655, 656 (AOE)
                -- immunobreak: 653, 654
                elseif L{85, 284}:contains(action.message) then -- regular resist spell
                    local spell_name = spell_util.spell_name(act.param)
                    if spell_name then
                        self:on_spell_resisted():trigger(self, spell_name, false)
                    end
                elseif L{655}:contains(action.message) then
                    local spell_name = spell_util.spell_name(act.param)
                    if spell_name then
                        self:on_spell_resisted():trigger(self, spell_name, true)
                    end
                end
            end
        end
    end
end

-------
-- Returns true if the monster has the given debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn boolean True if the monster has the given debuff, false otherwise
function Monster:has_debuff(debuff_id)
    return self.debuff_ids:contains(debuff_id)
end

-------
-- Returns the current target of the monster.
-- @treturn MobMetadata Returns the full metadata for the monster's target, or nil if the monster isn't targeting anyone
function Monster:get_current_target()
    return self.current_target
end

-------
-- Returns the full metadata for the mob that this class wraps.
-- @treturn MobMetadata Mob metadata
function Monster:get_mob()
    return windower.ffxi.get_mob_by_id(self.mob_id)
end

return Monster