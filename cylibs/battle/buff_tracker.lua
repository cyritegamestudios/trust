---------------------------
-- Tracks the buffs on party members.
-- @class module
-- @name BuffTracker

local buff_util = require('cylibs/util/buff_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local party_util = require('cylibs/util/party_util')

local BuffTracker = {}
BuffTracker.__index = BuffTracker
BuffTracker.__class = 'BuffTracker'

local Event = require('cylibs/events/Luvent')

-- Event called when the target gains a buff
function BuffTracker:on_gain_buff()
    return self.gain_buff
end

-- Event called when the target loses a buff
function BuffTracker:on_lose_buff()
    return self.lose_buff
end

-------
-- Default initializer for a new buff tracker.
-- @treturn BuffTracker A buff tracker
function BuffTracker.new()
    local self = setmetatable({
        action_events = {};
        active_buffs = {};
        debug = false;
        dispose_bag = DisposeBag.new();
    }, BuffTracker)

    self.gain_buff = Event.newEvent()
    self.lose_buff = Event.newEvent()

    -- Attempt to guess which buffs the player already has
    for party_member in party_util.get_party_members():it() do
        self.active_buffs[party_member.id] = L(party_util.get_buffs(party_member.id))
    end

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function BuffTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.dispose_bag:destroy()

    self.lose_buff:removeAllActions()
    self.gain_buff:removeAllActions()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before buffs will be tracked.
function BuffTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    -- Lose effect only shows up from 'action message' event
    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
        -- ${target} loses the effect of ${status}
        if message_id == 206 then
            self:on_lose_buff_from_spell(target_id, param_1)
        end
        if self.debug then
            print('message '..message_id) -- 266 ${target} gains the effect of ${status}
            print('param '..param_1) -- 195 paeon (status)
        end
    end), WindowerEvents.ActionMessage)

    -- Gain effect only shows up from 'action' event
    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        for _, target in pairs(act.targets) do
            local action = target.actions[1]
            if action then
                -- ${target} gains the effect of ${status}
                if action.message == 266 then
                    self:on_gain_buff_from_spell(target.id, action.param)
                elseif action.message == 230 then
                    self:on_gain_buff_from_spell(target.id, action.param)
                -- ${actor}'s ${spell} has no effect on ${target}
                elseif action.message == 75 then
                    local status = res.spells[act.param].status
                    if status then
                        self:on_gain_buff_from_spell(target.id, status)
                    end
                end
            end
        end
    end), WindowerEvents.Action)
end

-------
-- Call on every tic.
function BuffTracker:tic(_, _)
end

-------
-- Resets the buff tracker.
function BuffTracker:reset()
    self.active_buffs = {}
end

-------
-- Call when a target gains a buff.
-- @tparam number target_id Target id
-- @tparam number buff_id Buff id (see buffs.lua)
function BuffTracker:on_gain_buff_from_spell(target_id, buff_id)
    local target_buffs = self.active_buffs[target_id] or L{}
    target_buffs:append(buff_id)

    self.active_buffs[target_id] = target_buffs

    self:on_gain_buff():trigger(target_id, buff_id)

    -- Don't remove if it's the same buff
    local buffs_overwritten = buff_util.buffs_overwritten(buff_id, self.active_buffs[target_id])
    for buff_id in buffs_overwritten:it() do
        self:on_lose_buff_from_spell(target_id, buff_id)
    end

    if self.debug then
        local player = windower.ffxi.get_mob_by_id(target_id)
        print(player.name..' gains the effect of '..res.buffs:with('id', buff_id).en..', buffs are now '..tostring(self.active_buffs[target_id]))
    end
end

-------
-- Call when a target loses a buff.
-- @tparam number target_id Target id
-- @tparam number buff_id Buff id (see buffs.lua)
function BuffTracker:on_lose_buff_from_spell(target_id, buff_id)
    local target_buffs = self.active_buffs[target_id] or L{}
    target_buffs = target_buffs:filter(function(existing_buff_id) return existing_buff_id ~= buff_id  end)

    self.active_buffs[target_id] = target_buffs

    self:on_lose_buff():trigger(target_id, buff_id)

    if self.debug then
        local player = windower.ffxi.get_mob_by_id(target_id)
        print(player.name..' loses the effect of '..res.buffs:with('id', buff_id).en..', buffs are now '..tostring(self.active_buffs[target_id]))
    end
end

-------
-- Returns a target's buffs.
-- @tparam number target_id Target id
-- @treturn List Buff ids (see buffs.lua)
function BuffTracker:get_buffs(target_id)
   return self.active_buffs[target_id] or L{}
end

-------
-- Returns whether the target has a buff.
-- @tparam number target_id Target id
-- @tparam number buff Buff id (see buffs.lua)
-- @treturn Boolean True if the target has the given buff
function BuffTracker:has_buff(target_id, buff_id)
    return self:get_buffs(target_id):contains(buff_id)
end

return BuffTracker