---------------------------
-- Tracks the debuffs on a target.
-- @class module
-- @name DebuffTracker

local buff_util = require('cylibs/util/buff_util')
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

-------
-- Base (ungeared) durations in seconds for debuffs this tracker persists
-- across a Trust reload, keyed by the status name in res.buffs. These are
-- BASE durations: gear can only extend them (All Songs +, etc.), so a
-- restored debuff expires early rather than late -- the worst case is one
-- early recast, never a skipped cast. A partial resist can shorten a
-- debuff below its base duration; if Trust is reloaded in that window the
-- tracker may think it is up until the base duration ends, then it
-- self-corrects (see purge_expired). Debuffs not listed here are not
-- persisted and behave as before (recast after a reload).
local debuff_durations_by_name = {
    -- Bard songs
    ['Foe Requiem'] = 160,
    ['Requiem'] = 160,
    ['Carnage Elegy'] = 120,
    ['Elegy'] = 120,
    ['Lullaby'] = 30,
    -- Common enfeebles
    ['Slow'] = 180,
    ['Slow II'] = 180,
    ['Paralyze'] = 120,
    ['Paralyze II'] = 120,
    ['Blind'] = 120,
    ['Blind II'] = 120,
    ['Poison'] = 60,
    ['Poison II'] = 60,
    ['Bio'] = 60,
    ['Bio II'] = 60,
    ['Bio III'] = 60,
    ['Dia'] = 60,
    ['Dia II'] = 60,
    ['Dia III'] = 90,
    ['Sleep'] = 60,
    ['Sleep II'] = 90,
    ['Sleepga'] = 60,
    ['Sleepga II'] = 90,
    ['Silence'] = 120,
    ['Addle'] = 120,
    ['Distract'] = 120,
    ['Frazzle'] = 120,
    ['Gravity'] = 60,
    ['Gravity II'] = 120,
    ['Burn'] = 60,
    ['Choke'] = 60,
    ['Drown'] = 60,
    ['Frost'] = 60,
    ['Rasp'] = 60,
    ['Shock'] = 60,
}

-- Lazily resolved id -> duration map, built from the name table above.
-- Names that do not resolve in res.buffs are skipped, so a wrong name
-- just means that debuff is not persisted.
local duration_by_id = nil
local function duration_for(debuff_id)
    if duration_by_id == nil then
        duration_by_id = {}
        for name, duration in pairs(debuff_durations_by_name) do
            local id = buff_util.buff_id(name)
            if id then
                duration_by_id[id] = duration
            end
        end
    end
    return duration_by_id[debuff_id]
end

-- Path of the file this tracker's debuffs are saved to on unload, so a
-- later Trust load can restore them. One line per entry:
-- "<mob_id> <debuff_id> <added_at> <duration>".
local function debuff_state_path()
    return windower.addon_path .. 'data/debuff_state.txt'
end

local function read_state_file(path)
    local entries = {}
    local f = io.open(path, 'r')
    if not f then
        return entries
    end
    for line in f:lines() do
        local mob_id, debuff_id, added_at, duration, name = string.match(line, '^(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s*(.-)%s*$')
        if mob_id then
            entries[#entries + 1] = { mob_id = tonumber(mob_id), debuff_id = tonumber(debuff_id), added_at = tonumber(added_at), duration = tonumber(duration), name = (name ~= "" and name or nil) }
        end
    end
    f:close()
    return entries
end

local function write_state_file(path, entries)
    local f = io.open(path, 'w')
    if not f then
        return
    end
    -- Close the handle even if a write fails (disk full, etc.); the
    -- error still propagates to save_state's pcall and is logged there.
    local ok, err = pcall(function()
        for _, e in ipairs(entries) do
            local line = string.format('%d %d %d %d', e.mob_id, e.debuff_id, e.added_at, e.duration)
            if e.name then
                line = line .. ' ' .. e.name
            end
            f:write(line .. '\n')
        end
    end)
    f:close()
    if not ok then
        error(err)
    end
end


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
        debuff_added_at = {};
        debuff_durations = {};
        dispose_bag = DisposeBag.new();
    }, DebuffTracker)

    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function DebuffTracker:destroy()
    self:save_state()

    self.dispose_bag:destroy()

    self.lose_debuff:removeAllActions()
    self.gain_debuff:removeAllActions()
end

-------
-- Saves this mob's debuffs to disk so a later Trust load (a //lua reload
-- trust mid-fight, for example) can restore them instead of recasting.
-- Only debuffs with a known duration are saved. Expired entries, and this
-- mob's old entries, are dropped. A save failure is never fatal.
function DebuffTracker:save_state()
    local ok, err = pcall(function()
        local path = debuff_state_path()
        local now = os.time()
        local kept = {}
        for _, e in ipairs(read_state_file(path)) do
            if e.mob_id ~= self.mob_id and e.added_at + e.duration > now then
                kept[#kept + 1] = e
            end
        end
        -- destroy() also runs when the mob dies or despawns (MobTracker
        -- removal), not just on a Trust reload. A dead/gone mob's
        -- debuffs are over: persisting them lets a new same-name mob
        -- that recycles this id restore them via restore_state (the
        -- name check cannot tell two same-species mobs apart), and the
        -- Debuffer would skip recasting on a fresh mob. The mob's old
        -- entries are already dropped by the filter above, so just
        -- don't re-add them. On a genuine reload mid-fight the mob is
        -- alive and in memory, so the feature is unchanged.
        local mob = windower.ffxi.get_mob_by_id(self.mob_id)
        local mob_alive = mob ~= nil and (mob.hpp == nil or mob.hpp > 0)
        if mob_alive then
            for debuff_id in self.debuff_ids:it() do
                local duration = self.debuff_durations[debuff_id]
                local added_at = self.debuff_added_at[debuff_id]
                if duration and added_at and added_at + duration > now then
                    kept[#kept + 1] = { mob_id = self.mob_id, debuff_id = debuff_id, added_at = added_at, duration = duration, name = monster_util.monster_name(self.mob_id) }
                end
            end
        end
        write_state_file(path, kept)
    end)
    if not ok then
        logger.warning(self.__class, 'save_state', 'failed to save debuff state', tostring(err))
    end
end

-------
-- Restores this mob's debuffs saved by an earlier Trust load, if they
-- have not expired yet. Restored debuffs keep their original added time
-- and duration, so they expire on schedule and the Debuffer recasts them
-- when they actually wear off.
function DebuffTracker:restore_state()
    local ok, err = pcall(function()
        local now = os.time()
        local current_name = monster_util.monster_name(self.mob_id)
        for _, e in ipairs(read_state_file(debuff_state_path())) do
            if e.mob_id == self.mob_id and e.added_at + e.duration > now and not (e.name and current_name ~= "Unknown" and e.name ~= current_name) then
                self:add_debuff(e.debuff_id)
                -- add_debuff stamps the current time; keep the original
                -- time so the expiry stays correct.
                self.debuff_added_at[e.debuff_id] = e.added_at
                self.debuff_durations[e.debuff_id] = e.duration
            end
        end
    end)
    if not ok then
        logger.warning(self.__class, 'restore_state', 'failed to restore debuff state', tostring(err))
    end
end

-------
-- Drops restored debuffs whose base duration has run out. The tracker
-- only learns about a debuff wearing off from a LoseDebuff event, which
-- it cannot see while Trust is unloaded, so restored entries are expired
-- lazily here instead. Called on every read, so a stale entry self-
-- corrects at most one Debuffer check (6s) after its expiry.
function DebuffTracker:purge_expired()
    local now = os.time()
    local expired = {}
    for debuff_id in self.debuff_ids:it() do
        local added_at = self.debuff_added_at[debuff_id]
        local duration = self.debuff_durations[debuff_id]
        if added_at and duration and added_at + duration <= now then
            expired[#expired + 1] = debuff_id
        end
    end
    for _, debuff_id in ipairs(expired) do
        self.debuff_ids:remove(debuff_id)
        self.debuff_added_at[debuff_id] = nil
        self.debuff_durations[debuff_id] = nil
        self:on_lose_debuff():trigger(self.mob_id, debuff_id)
    end
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before buffs will be tracked.
function DebuffTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    -- Pick up debuffs saved by an earlier Trust load for this same mob,
    -- so the Debuffer does not recast them after a //lua reload trust.
    self:restore_state()

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
                                self.debuff_added_at[debuff_id] = nil
                                self.debuff_durations[debuff_id] = nil
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
                    local buff = res.buffs[debuff_id]
                    logger.notice(self.__class, 'on_message_received', 'remove_debuff', (buff and buff.en or "unknown"))
                    self:remove_debuff(debuff_id)
                end
            end
        elseif ipc_message.__class == GainDebuffMessage.__class then
            local mob_id = ipc_message:get_mob_id()
            if mob_id == self.mob_id then
                local debuff_id = ipc_message:get_buff_id()
                if debuff_id then
                    local buff = res.buffs[debuff_id]
                    logger.notice(self.__class, 'on_message_received', 'add_debuff', (buff and buff.en or "unknown"))
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
    self.debuff_added_at = {}
    self.debuff_durations = {}
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
        self.debuff_added_at[debuff_id] = os.time()
        -- Debuffs with no known duration fall back to 180s so they
        -- expire instead of living forever (purge_expired only
        -- purges entries with a duration).
        self.debuff_durations[debuff_id] = duration_for(debuff_id) or 180
        self:on_gain_debuff():trigger(self.mob_id, debuff_id)
    end
end

function DebuffTracker:remove_debuff(debuff_id)
    if self:has_debuff(debuff_id) then
        logger.notice(self.__class, 'lose_debuff', monster_util.monster_name(self.mob_id), buff_util.buff_name(debuff_id))

        self.debuff_ids:remove(debuff_id)
        self.debuff_added_at[debuff_id] = nil
        self.debuff_durations[debuff_id] = nil
        self:on_lose_debuff():trigger(self.mob_id, debuff_id)
    end
end

-------
-- Returns a target's debuffs.
-- @treturn List Debuff ids (see buffs.lua)
function DebuffTracker:get_debuff_ids()
    self:purge_expired()
    return self.debuff_ids
end

-------
-- Returns whether the target has a debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn Boolean True if the target has the given debuff
function DebuffTracker:has_debuff(debuff_id)
    self:purge_expired()
    return self.debuff_ids:contains(debuff_id)
end

return DebuffTracker