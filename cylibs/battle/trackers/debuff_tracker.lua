---------------------------
-- Tracks the debuffs on a target.
-- @class module
-- @name DebuffTracker

local buffs_ext = require('cylibs/res/buffs')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GainDebuffMessage = require('cylibs/messages/gain_buff_message')
local LoseDebuffMessage = require('cylibs/messages/lose_buff_message')
local monster_util = require('cylibs/util/monster_util')
local weapon_skills_ext = require('cylibs/res/weapon_skills')

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
-- Default initializer for a new debuff tracker.
-- @treturn BuffTracker A buff tracker
function DebuffTracker.new(mob_id)
    local self = setmetatable({
        mob_id = mob_id;
        debuff_ids = S{};
        dispose_bag = DisposeBag.new();
    }, DebuffTracker)

    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function DebuffTracker:destroy()
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
            self:add_debuff(debuff_id)
        end
    end), WindowerEvents.GainDebuff)

    self.dispose_bag:add(WindowerEvents.LoseDebuff:addAction(function(mob_id, debuff_id)
        if mob_id == self.mob_id then
            self:remove_debuff(debuff_id)
        end
    end), WindowerEvents.LoseDebuff)

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if action.targets == nil then return end

        for _,target in pairs(action.targets) do
            if target.id == self.mob_id then
                if action.category == 3 then
                    local weapon_skill = weapon_skills_ext[action.param]
                    if weapon_skill then
                        for debuff_id in L(weapon_skill.status):it() do
                            self:add_debuff(debuff_id)
                        end
                    end
                end
                for _,action in pairs(target.actions) do
                    if type(action) ~= 'number' then
                        if action.message == 644 then
                            logger.notice(self.__class, 'lose_all_debuffs', monster_util.monster_name(self.mob_id))
                            local debuff_ids = self:get_debuff_ids():copy()
                            self.debuff_ids:clear()
                            for debuff_id in debuff_ids:it() do
                                self:on_lose_debuff():trigger(self.mob_id, debuff_id)
                            end
                        elseif L{ 1 }:contains(action.message) then
                            for sleep_debuff_id in L{ 2, 19 }:it() do
                                self:remove_debuff(sleep_debuff_id)
                            end
                        end
                    end
                end
            end
        end
    end), WindowerEvents.Action)

    self.dispose_bag:add(IpcRelay.shared():on_message_received():addAction(function(ipc_message)
        if ipc_message.__class == LoseDebuffMessage.__class then
            local mob_id = ipc_message:get_mob_id()
            if mob_id == self.mob_id then
                local debuff_id = ipc_message:get_buff_id()
                if debuff_id then
                    logger.notice(self.__class, 'on_message_received', 'remove_debuff', res.buffs[debuff_id].en)
                    self:remove_debuff(debuff_id)
                end
            end
        elseif ipc_message.__class == GainDebuffMessage.__class then
            local mob_id = ipc_message:get_mob_id()
            if mob_id == self.mob_id then
                local debuff_id = ipc_message:get_buff_id()
                if debuff_id then
                    logger.notice(self.__class, 'on_message_received', 'add_debuff', res.buffs[debuff_id].en)
                    self:add_debuff(debuff_id)
                end
            end
        end
    end), IpcRelay.shared():on_message_received())
end

function DebuffTracker:tic(_, _)
end

-------
-- Resets the debuff tracker.
function DebuffTracker:reset()
    self.debuff_ids = S{}
end

function DebuffTracker:add_debuff(debuff_id)
    if not self:has_debuff(debuff_id) and buff_util.is_debuff(debuff_id) then
        logger.notice(self.__class, 'gain_debuff', monster_util.monster_name(self.mob_id), buff_util.buff_name(debuff_id))

        local debuff = buffs_ext[debuff_id]
        if debuff then
            local overwrites = L(debuff.overwrites)
            for overwritten_debuff_id in overwrites:it() do
                self:remove_debuff(overwritten_debuff_id)
            end
        end
        self.debuff_ids:add(debuff_id)
        self:on_gain_debuff():trigger(self.mob_id, debuff_id)
    end
end

function DebuffTracker:remove_debuff(debuff_id)
    if self:has_debuff(debuff_id) then
        logger.notice(self.__class, 'lose_debuff', monster_util.monster_name(self.mob_id), buff_util.buff_name(debuff_id))

        self.debuff_ids:remove(debuff_id)
        self:on_lose_debuff():trigger(self.mob_id, debuff_id)
    end
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