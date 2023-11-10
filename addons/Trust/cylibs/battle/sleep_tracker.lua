---------------------------
-- Tracks whether nearby mobs are sleeping.
-- @class module
-- @name SleepTracker

local action_message_util = require('cylibs/util/action_message_util')
local buff_util = require('cylibs/util/buff_util')

local SleepTracker = {}
SleepTracker.__index = SleepTracker

-------
-- Default initializer for a new battle stat stracker.
-- @treturn SleepTracker A battle stat tracker
function SleepTracker.new()
    local self = setmetatable({
        action_events = {};
        sleeping_mob_ids = T{};
    }, SleepTracker)

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function SleepTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before functions like get_current_target().
-- Before this object is disposed of, stop_tracking() should be called.
function SleepTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.action_events.action = windower.register_event('action', function(act)
        local actor = windower.ffxi.get_mob_by_id(act.actor_id)
        if actor then
            if actor.spawn_type == 16 then
                self:handle_action_by_monster(act)
            else
                self:handle_action_on_monster(act)
            end
        end
    end)
end

function SleepTracker:handle_action_by_monster(act)
    if self.sleeping_mob_ids[act.actor_id] then
        self.sleeping_mob_ids[act.actor_id] = nil
    end
end

function SleepTracker:handle_action_on_monster(act)
    for _, target in pairs(act.targets) do
        local target_id = target.id
        local action = target.actions[1]
        if action then
            if action_message_util.is_gain_debuff_message(action.message) then
                local debuff = buff_util.debuff_for_spell(act.param)
                if debuff and debuff.en == 'sleep' then
                    self.sleeping_mob_ids[target_id] = true
                end
            end
        end
    end
end

-------
-- Resets the battle stats.
function SleepTracker:reset()
    self.sleeping_mob_ids = T{}
end

function SleepTracker:is_sleeping(target_id)
    return self.sleeping_mob_ids[target_id] ~= nil
end

-------
-- Returns the player's accuracy since the battle stat tracker was last reset.
-- @treturn number Player's accuracy (between 0 and 100)
function SleepTracker:get_num_sleeping_mobs()
    return L(self.sleeping_mob_ids:keyset()):length()
end

return SleepTracker