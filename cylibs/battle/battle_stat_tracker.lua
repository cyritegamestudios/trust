---------------------------
-- Tracks a player's battle stats (e.g. accuracy)
-- @class module
-- @name BattleStatTracker

require('tables')
require('lists')
require('logger')

local action_message_util = require('cylibs/util/action_message_util')
local DisposeBag = require('cylibs/events/dispose_bag')

local BattleStatTracker = {}
BattleStatTracker.__index = BattleStatTracker

-------
-- Default initializer for a new battle stat stracker.
-- @tparam number player_id Player id
-- @treturn BattleStatTracker A battle stat tracker
function BattleStatTracker.new(player_id)
    local self = setmetatable({
        action_events = {};
        player_id = player_id;
        hit_sum = 0;
        num_hits = 0;
        dispose_bag = DisposeBag.new();
    }, BattleStatTracker)

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function BattleStatTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    self.dispose_bag:destroy()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before functions like get_current_target().
-- Before this object is disposed of, stop_tracking() should be called.
function BattleStatTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if action.actor_id ~= self.player_id or action.targets == nil then return end

        for _,target in pairs(action.targets) do
            for _,action in pairs(target.actions) do
                if type(action) ~= 'number' then
                    if action_message_util.is_miss_attack_message(action.message) then
                        self.num_hits = self.num_hits + 1
                    end

                    if action_message_util.is_hit_attack_message(action.message) then
                        self.hit_sum = self.hit_sum + 1
                        self.num_hits = self.num_hits + 1
                    end
                end
            end
        end
    end), WindowerEvents.Action)
end

-------
-- Resets the battle stats.
function BattleStatTracker:reset()
    self.hit_sum = 0
    self.num_hits = 0
end

-------
-- Returns the player's accuracy since the battle stat tracker was last reset.
-- @treturn number Player's accuracy (between 0 and 100)
function BattleStatTracker:get_accuracy()
    if self.num_hits < 6 then return 100 end

    return (self.hit_sum / self.num_hits) * 100.0
end

return BattleStatTracker