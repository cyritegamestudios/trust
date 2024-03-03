---------------------------
-- Tracks the debuffs on monsters.
-- @class module
-- @name DebuffTracker

local buff_util = require('cylibs/util/buff_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')

local DebuffTracker = {}
DebuffTracker.__index = DebuffTracker
DebuffTracker.__class = 'DebuffTracker'


-- Event called when the target gains a debuff
function DebuffTracker:on_gain_debuff()
    return self.gain_debuff
end

-- Event called when the target loses a debuff
function DebuffTracker:on_lose_debuff()
    return self.lose_debuff
end

-------
-- Default initializer for a new buff tracker.
-- @treturn BuffTracker A buff tracker
function DebuffTracker.new(mob_id)
    local self = setmetatable({
        mob_id = mob_id;
        action_events = {};
        debuff_ids = {};
        dispose_bag = DisposeBag.new();
    }, DebuffTracker)

    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function DebuffTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.dispose_bag:destroy()

    self.lose_debuff:removeAllActions()
    self.gain_debuff:removeAllActions()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before buffs will be tracked.
function DebuffTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.GainDebuff:addAction(function(mob_id, debuff_id)
        if mob_id == self.mob_id then
            logger.notice(self.__class, 'gain_debuff', windower.ffxi.get_mob_by_id(mob_id).name, res.buffs[debuff_id].en)
            self.debuff_ids:add(debuff_id)
        end
    end), WindowerEvents.Action)
end

-------
-- Call on every tic.
function DebuffTracker:tic(_, _)
end

-------
-- Resets the debuff tracker.
function DebuffTracker:reset()
    self.debuff_ids = S{}
end

-------
-- Returns a target's debuffs.
-- @treturn List Debuff ids (see buffs.lua)
function DebuffTracker:get_debuff_ids()
    return self.debuff_ids
end

-------
-- Returns whether the target has a debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn Boolean True if the target has the given debuff
function DebuffTracker:has_debuff(debuff_id)
    return self:get_debuff_ids():contains(debuff_id)
end

return DebuffTracker