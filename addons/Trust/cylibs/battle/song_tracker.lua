---------------------------
-- Tracks the songs on a list of players.
-- @class module
-- @name SongTracker

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local list_ext = require('cylibs/util/extensions/lists')
local logger = require('cylibs/logger/logger')
local SongRecord = require('cylibs/battle/songs/song_record')

local SongTracker = {}
SongTracker.__index = SongTracker

-- Event called when a song is < 45 seconds from wearing off
function SongTracker:on_song_duration_warning()
    return self.song_duration_warning
end

-- Event called when active songs change
function SongTracker:on_songs_changed()
    return self.songs_changed
end

-------
-- Default initializer for a new song tracker.
-- @tparam number player_ids Player ids to track
-- @tparam List dummy_songs List of dummy songs (see spell.lua)
-- @tparam List songs List of songs (see spell.lua)
-- @tparam List pianissimo_songs List of songs to be sung with pianissimo after songs (see spell.lua)
-- @treturn SongTracker A song tracker
function SongTracker.new(player, dummy_songs, songs, pianissimo_songs, job)
    local self = setmetatable({
        action_events = {};
        player = player;
        dummy_songs = dummy_songs;
        pianissimo_songs = pianissimo_songs;
        songs = songs;
        job = job;
        active_songs = {};
        last_expiration_check = os.time();
    }, SongTracker)

    self.dispose_bag = DisposeBag.new()
    self.song_duration_warning = Event.newEvent()
    self.songs_changed = Event.newEvent()

    -- Attempt to guess which songs the player already has based on active buffs
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    for song in dummy_songs:it() do
        local buff_id = res.buffs:with('id', song:get_spell().status).id
        if buff_util.is_buff_active(buff_id, player_buff_ids) then
            self:on_gain_song(windower.ffxi.get_player().id, song:get_spell().id, buff_id)
        end
    end

    local song_buff_ids = player_buff_ids:filter(function(buff_id) return job:is_bard_song_buff(buff_id) end)
    for song in songs:it() do
        local buff_id = res.buffs[song:get_spell().status].id
        if song_buff_ids:contains(buff_id) then
            song_buff_ids:remove(song_buff_ids:indexOf(buff_id))
            self:on_gain_song(windower.ffxi.get_player().id, song:get_spell().id, buff_id)
        end
    end

    self:set_expiring_soon(windower.ffxi.get_player().id)

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function SongTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.song_duration_warning:removeAllActions()
    self.songs_changed:removeAllActions()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before songs will be tracked.
function SongTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(self.player:on_spell_finish():addAction(
            function (_, song_id, targets)
                local song = res.spells:with('id', song_id)
                if song.type == 'BardSong' and song.status and self.job:is_bard_song_buff(song.status) then
                    for _, target in pairs(targets) do
                        local action = target.actions[1]
                        if action then
                            -- ${target} gains the effect of ${status}
                            if action.message == 266 then
                                self:on_gain_song(target.id, song_id, action.param)
                            elseif action.message == 230 then
                                self:on_gain_song(target.id, song_id, action.param)
                            end
                        end
                    end
                end
            end), self.player:on_spell_finish())

    self.action_events.zone_change = windower.register_event('zone change', function()
        self:reset()
    end)

    self.action_events.gain_buff = windower.register_event('gain buff', function(buff_id)
        if self.job:is_bard_song_buff(buff_id) then
            self:prune_songs(windower.ffxi.get_player().id, self.dummy_songs, L(windower.ffxi.get_player().buffs))
        end
    end)

    self.action_events.lose_buff = windower.register_event('lose buff', function(buff_id)
        if self.job:is_bard_song_buff(buff_id) then
            logger.notice(windower.ffxi.get_player().name.."'s", "effect of", res.buffs[buff_id].name, "wears off")
            self:prune_songs(windower.ffxi.get_player().id, self.dummy_songs, L(windower.ffxi.get_player().buffs))
            self:prune_songs(windower.ffxi.get_player().id, self.songs, L(windower.ffxi.get_player().buffs))
        end
    end)
end

-------
-- Call on every tic.
function SongTracker:tic(_, _)
    self:check_song_expiration()
end

-------
-- Checks to see if songs are expiring soon an triggers on_song_duration_warning() for all expiring songs.
function SongTracker:check_song_expiration()
    if os.time() - self.last_expiration_check < 10 then
        return
    end
    self.last_expiration_check = os.time()
    local target_id = windower.ffxi.get_player().id
    if self.active_songs[target_id] then
        for song_record in self.active_songs[target_id]:it() do
            logger.notice(song_record:get_expire_time() - os.time(), "seconds remaining on", res.spells[song_record:get_song_id()].name)
            if song_record:is_expired() then
                self:on_lose_song(target_id, song_record:get_song_id(), song_record:get_buff_id())
                logger.notice(res.spells[song_record:get_song_id()].name, "is expired")
            elseif song_record:get_expire_time() - os.time() < 45 then
                self:on_song_duration_warning():trigger(song_record)
                logger.notice(res.spells[song_record:get_song_id()].name, "is expiring soon")
            end
        end
    end
end

-------
-- Checks to see if any of the given songs are expiring soon.
-- @treturn boolean True if a song is expiring in less than 45 seconds.
function SongTracker:is_expiring_soon(target_id, songs)
    if target_id ~= windower.ffxi.get_player().id then
        return false
    end
    if self.active_songs[target_id] then
        for song_record in self.active_songs[target_id]:it() do
            for song in songs:it() do
                if song_record:get_song_id() == song:get_spell().id and song_record:get_expire_time() - os.time() < 45 then
                    return true
                end
            end
        end
    end
    return false
end

-------
-- Sets all songs to expire soon.
-- @tparam number target_id Target id
function SongTracker:set_expiring_soon(target_id)
    if not self.active_songs[target_id] then
        return
    end
    local active_songs = self.active_songs[target_id]:sort(function(song_record1, song_record2)
        return song_record1:get_expire_time() < song_record2:get_expire_time()
    end)
    local i = 0
    for song_record in active_songs:it() do
        local new_expire_time = os.time() + 45 + i * 3
        song_record:set_expire_time(new_expire_time)
        i = i + 1
        logger.notice("Setting expiration time of", res.spells[song_record:get_song_id()].name, "to", new_expire_time)
    end
end

-------
-- Resets song records.
function SongTracker:reset()
    self.active_songs = {}

    for target_id, target_songs in pairs(self.active_songs) do
        self:on_songs_changed():trigger(self, target_id, target_songs)
    end
end

-------
-- Call when a target gains a song.
-- @tparam number target_id Target id
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam number song_duration (optional) Song duration, or job default if not specified
function SongTracker:on_gain_song(target_id, song_id, buff_id, song_duration)
    if self:has_song(target_id, song_id) then
        self:on_lose_song(target_id, song_id, buff_id)
    end

    local target_songs = (self.active_songs[target_id] or S{}):add(SongRecord.new(song_id, song_duration or self.job:get_song_duration()))

    self.active_songs[target_id] = target_songs

    self:on_songs_changed():trigger(self, target_id, self.active_songs[target_id])

    local target = windower.ffxi.get_mob_by_id(target_id)
    logger.notice(target.name, "gains the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
end

-------
-- Call when a target loses a song.
-- @tparam number target_id Target id
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number buff_id Buff id (see buffs.lua)
function SongTracker:on_lose_song(target_id, song_id, buff_id)
    if not self:has_song(target_id, song_id) then
        return
    end

    -- 206: ${target}'s ${status} effect wears off.
    local target_songs = (self.active_songs[target_id] or S{}):filter(function(song_record) return song_record:get_song_id() ~= song_id  end)

    self.active_songs[target_id] = target_songs

    self:on_songs_changed():trigger(self, target_id, self.active_songs[target_id])

    local target = windower.ffxi.get_mob_by_id(target_id)
    logger.notice(target.name, "loses the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
end

-------
-- Removes songs and dummy songs from the song id list that are no longer active.
-- @tparam number target_id Target id
-- @tparam List buff_ids The target's buff ids (see buffs.lua)
function SongTracker:prune_all_songs(target_id, buff_ids)
    self:prune_songs(target_id, self.dummy_songs, buff_ids)
    self:prune_songs(target_id, self.songs, buff_ids)
    self:prune_songs(target_id, self.pianissimo_songs, buff_ids)
end

-------
-- Removes songs from the song id list that are no longer active.
-- @tparam number target_id Target id
-- @tparam List songs List of songs (see Spell.lua)
-- @tparam List buff_ids The target's buff ids (see buffs.lua)
function SongTracker:prune_songs(target_id, songs, buff_ids)
    if self.debug then
        local target = windower.ffxi.get_mob_by_id(target_id)
        print('Checking songs for '..target.name..': ')
    end
    for song in songs:it() do
        if self.debug then
            print('Checking '..song:get_spell().en)
        end
        if not buff_util.is_buff_active(song:get_spell().status, buff_ids) then
            if self.debug then
                print(song:get_spell().en..' is no longer active, buff_ids: '..tostring(buff_ids))
            end
            self:on_lose_song(target_id, song:get_spell().id, song:get_spell().status)
        end
    end
end

-------
-- Prunes expired songs from the target.
-- @tparam number target_id Target id
function SongTracker:prune_expired_songs(target_id)
    if self.debug then
        print('pruning expired songs for '..windower.ffxi.get_mob_by_id(target_id).name)
    end
    if self.active_songs[target_id] then
        for song_record in self.active_songs[target_id]:it() do
            if song_record:is_expired() then
                self:on_lose_song(target_id, song_record:get_song_id(), song_record:get_buff_id())
                if self.debug then
                    print(res.spells:with('id', song_record:get_song_id()).name..' is expired')
                    print('songs are now '..tostring(self.active_songs[target_id]:map(function(record) return record:tostring() end)))
                end
            else
                if self.debug then
                    print('time left on '..res.spells:with('id', song_record:get_song_id()).name..' is '..(song_record:get_expire_time() - os.time()))
                end
            end
        end
    end
end

-------
-- Returns whether the target has a song.
-- @tparam number target_id Target id
-- @tparam number song_id Song id (see spells.lua)
-- @tparam List buff_ids The target's buff ids (see buffs.lua)
-- @treturn Boolean True if the target has the given song
function SongTracker:has_song(target_id, song_id, buff_ids)
    if self.active_songs[target_id] and self.active_songs[target_id]:filter(function(song_record) return song_record:get_song_id() == song_id end):length() > 0 then
        if buff_ids and not buff_ids:contains(res.spells:with('id', song_id).status) then
            self:prune_all_songs(target_id, buff_ids)
            return false
        end
        return true
    end
    return false
end

-------
-- Returns whether the player has at least one of the given songs active.
-- @tparam number target_id Target id
-- @tparam List song_ids Song ids (see spells.lua)
-- @tparam List buff_ids Buff ids for target's current buffs (see buffs.lua)
-- @treturn Boolean True if at least one of the given songs is active
function SongTracker:has_any_song(target_id, song_ids, buff_ids)
    for song_id in song_ids:it() do
        if self:has_song(target_id, song_id, buff_ids) then
            return true
        end
    end
    return false
end

-------
-- Returns whether the player has all of the given songs active.
-- @tparam number target_id Target id
-- @tparam List song_ids Song ids (see spells.lua)
-- @tparam List buff_ids Buff ids for player's current buffs (see buffs.lua)
-- @treturn Boolean True if all of the given songs are active
function SongTracker:has_all_songs(target_id, song_ids, buff_ids)
    local songs_active = song_ids:filter(function(song_id)
        return self:has_song(target_id, song_id, buff_ids)
    end)
    return songs_active:length() >= self.job:get_max_num_songs()
end

-------
-- Returns a target's songs.
-- @tparam number target_id Target id
-- @treturn List Buff ids (see buffs.lua)
function SongTracker:get_songs(target_id)
    return S(self.active_songs[target_id]) or S{}
end

-------
-- Returns the number of songs the player has active, optionally filtering by a given list of songs.
-- @tparam number target_id Target id
-- @tparam List buff_ids Buff ids for player's current buffs (see buffs.lua)
-- @tparam List song_ids Song ids, optional (see spells.lua)
-- @treturn number Number of songs active
function SongTracker:get_num_songs(target_id, buff_ids, song_list)
    if song_list and not song_list:empty() then
        local num_songs = 0
        for song in song_list:it() do
            if self:has_song(target_id, song:get_spell().id, buff_ids) then
                num_songs = num_songs + 1
            end
        end
        return num_songs
    else
        return (self.active_songs[target_id] or S{}):length()
    end
end

return SongTracker