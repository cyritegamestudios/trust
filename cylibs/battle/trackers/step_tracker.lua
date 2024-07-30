---------------------------
-- Tracks steps on a target.
-- @class module
-- @name StepTracker

local buffs_ext = require('cylibs/res/buffs')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GainDebuffMessage = require('cylibs/messages/gain_buff_message')
local LoseDebuffMessage = require('cylibs/messages/lose_buff_message')
local monster_util = require('cylibs/util/monster_util')
local weapon_skills_ext = require('cylibs/res/weapon_skills')

local StepTracker = {}
StepTracker.__index = StepTracker
StepTracker.__class = 'StepTracker'


-- Event called when the target gains a daze
function StepTracker:on_gain_daze()
    return self.gain_daze
end

-- Event called when the target loses a daze
function StepTracker:on_lose_daze()
    return self.lose_daze
end

-------
-- Default initializer for a new step tracker.
-- @treturn StepTracker A step tracker
function StepTracker.new(mob_id, debuff_tracker)
    local self = setmetatable({
        mob_id = mob_id;
        debuff_tracker = debuff_tracker;
        active_steps = T{};
        dispose_bag = DisposeBag.new();
    }, StepTracker)

    self.gain_daze = Event.newEvent()
    self.lose_daze = Event.newEvent()

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function StepTracker:destroy()
    self.dispose_bag:destroy()

    self.gain_daze:removeAllActions()
    self.lose_daze:removeAllActions()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before steps will be tracked.
function StepTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        if act.targets == nil then return end

        for _, target in pairs(act.targets) do
            local action = target.actions[1]
            if action then
                if self:get_daze_action_messages():contains(action.message) then
                    local level = action.param
                    local daze_name = self:get_daze_name(action.message)

                    self:add_daze(daze_name, level)
                end
            end
        end
    end), WindowerEvents.Action)
end

function StepTracker:tic(_, _)
end

-------
-- Resets the step tracker.
function StepTracker:reset()
    self.active_steps = S{}
end

function StepTracker:get_daze_action_messages()
    return S{ 520 }
end

function StepTracker:get_daze_name(message_id, level)
    local message_to_name = {
        [519] = "Lethargic Daze",
        [520] = "Sluggish Daze",
        [521] = "Weakened Daze",
    }
    if level == nil then
        return message_to_name[message_id]
    else
        return message_to_name[message_id]..' '..level
    end
end

function StepTracker:add_daze(daze_name, level)
    if not self:has_daze(daze_name, level) then
        logger.notice(self.__class, 'add_daze', monster_util.monster_name(self.mob_id), daze_name, level)

        self:remove_daze(daze_name)

        self.active_steps[daze_name] = level

        local debuff_id = buff_util.buff_id(daze_name..' '..level)
        if debuff_id then
            self.debuff_tracker:add_debuff(debuff_id)
        end

        self:on_gain_daze():trigger(self.mob_id, daze_name, level)
    end
end

function StepTracker:remove_daze(daze_name)
    if self:has_daze(daze_name) then
        local current_level = self.active_steps[daze_name]

        logger.notice(self.__class, 'remove_daze', monster_util.monster_name(self.mob_id), daze_name, current_level)

        local debuff_id = buff_util.buff_id(daze_name..' '..current_level)
        if debuff_id then
            self.debuff_tracker:remove_debuff(debuff_id)
        end

        self.active_steps[daze_name] = 0
        self:on_lose_daze():trigger(self.mob_id, daze_name, current_level)
    end
end

-------
-- Returns the level for the given daze.
-- @treturn number Level of daze
function StepTracker:get_daze_level(daze_name)
    return self.active_steps[daze_name] or 0
end

-------
-- Returns whether the target has a daze. If no level is specified,
-- returns true if the target has any non-zero daze level.
-- @tparam string daze_name Name of daze (e.g. Sluggish Daze)
-- @tparam number level Optional level of daze
-- @treturn Boolean True if the target has a daze >= the given level
function StepTracker:has_daze(daze_name, level)
    if self.active_steps[daze_name] == nil then
        return false
    end
    if level == 0 or level == nil then
        return self.active_steps[daze_name] > 0
    else
        return self.active_steps[daze_name] >= level
    end
end

return StepTracker