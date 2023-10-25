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

-- Event called when a song is < self.expiring_duration seconds from wearing off
function SongTracker:on_song_duration_warning()
    return self.song_duration_warning
end

-- Event called when active songs change
function SongTracker:on_songs_changed()
    return self.songs_changed
end

-------
-- Default initializer for a new song tracker.
-- @tparam Player player Player entity
-- @tparam Party party Player's party
-- @tparam List dummy_songs List of dummy songs (see spell.lua)
-- @tparam List songs List of songs (see spell.lua)
-- @tparam List pianissimo_songs List of songs to be sung with pianissimo after songs (see spell.lua)
-- @treturn SongTracker A song tracker
function SongTracker.new(player, party, dummy_songs, songs, pianissimo_songs, job)
    local self = setmetatable({
        action_events = {};
        player = player;
        party = party;
        dummy_songs = dummy_songs;
        pianissimo_songs = pianissimo_songs;
        songs = songs;
        job = job;
        active_songs = {};
        expiring_duration = 60;
        last_expiration_check = os.time();
    }, SongTracker)

    self.dispose_bag = DisposeBag.new()
    self.song_duration_warning = Event.newEvent()
    self.songs_changed = Event.newEvent()

    local has_songs = false
    local all_songs = dummy_songs:extend(songs):extend(pianissimo_songs)
    for party_member in party:get_party_members(true):it() do
        for song in all_songs:it() do
            local buff_id = res.buffs:with('id', song:get_spell().status).id
            if buff_util.is_buff_active(buff_id, party_member:get_buff_ids()) then
                has_songs = true
                self:on_gain_song(party_member:get_id(), song:get_spell().id, buff_id)
            end
        end
        logger.notice(party_member:get_name().."'s", "songs are", self:get_songs(party_member:get_id()):map(function(song_record) return res.spells[song_record:get_song_id()].name end))
    end

    if has_songs then
        party:add_to_chat(self.party:get_player(), "It looks like there are already some active songs. I'll try my best to figure out what they are.")

        self:set_expiring_soon(windower.ffxi.get_player().id)
    end

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

    self.dispose_bag:destroy()

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

    for party_member in self.party:get_party_members(true):it() do
        self.dispose_bag:add(party_member:on_gain_buff():addAction(function(p, buff_id)
            if self.job:is_bard_song_buff(buff_id) then
                logger.notice(p:get_name(), "gains the effect of", res.buffs[buff_id].name)
                self:prune_all_songs(p:get_id(), p:get_buff_ids())
            end
        end), party_member:on_gain_buff())

        self.dispose_bag:add(party_member:on_lose_buff():addAction(function(p, buff_id)
            if self.job:is_bard_song_buff(buff_id) then
                logger.notice(p:get_mob().name.."'s", "effect of", res.buffs[buff_id].name, "wears off")
                self:prune_all_songs(p:get_id(), p:get_buff_ids())
            end
        end), party_member:on_lose_buff())
    end
end

-------
-- Call on every tic.
function SongTracker:tic(_, _)
    self:check_song_expiration()
end

-------
-- Checks to see if songs are expiring soon an triggers on_song_duration_warning() for all expiring songs.
function SongTracker:check_song_expiration()
    if os.time() - self.last_expiration_check < 9 then
        return
    end
    self.last_expiration_check = os.time()

    for target_id, song_records in pairs(self.active_songs) do
        if song_records then
            local target = windower.ffxi.get_mob_by_id(target_id)
            for song_record in song_records:it() do
                logger.notice(target.name.."'s", res.spells[song_record:get_song_id()].name, "has", song_record:get_expire_time() - os.time(), "seconds remaining")
                if song_record:is_expired() then
                    self:on_lose_song(target_id, song_record:get_song_id(), song_record:get_buff_id())
                    logger.notice(target.name.."'s", res.spells[song_record:get_song_id()].name, "is expired")
                elseif song_record:get_expire_time() - os.time() < self.expiring_duration then
                    self:on_song_duration_warning():trigger(song_record)
                    logger.notice(target.name.."'s", res.spells[song_record:get_song_id()].name, "is expiring soon")
                end
            end
        end
    end

end

-------
-- Checks to see if any of the given songs are expiring soon.
-- @treturn boolean True if a song is expiring in less than self.expiring_duration seconds.
function SongTracker:is_expiring_soon(target_id, songs)
    if self.active_songs[target_id] then
        for song_record in self.active_songs[target_id]:it() do
            for song in songs:it() do
                if song_record:get_song_id() == song:get_spell().id and song_record:get_expire_time() - os.time() < self.expiring_duration then
                    return true
                end
            end
        end
    end
    return false
end

-------
-- Returns the subset of the given songs that are expiring soon.
-- @treturn list List of expiring songs
function SongTracker:get_expiring_songs(target_id, songs)
    local expiring_songs = songs:filter(function(song)
        return self:is_expiring_soon(target_id, L{ song })
    end)
    return expiring_songs
end

-------
-- Sets all songs to expire soon.
-- @tparam number target_id Target id
-- @tparam number expiring_in (optional) Number of seconds until first song expires (defaults to self.expiring_duration)
function SongTracker:set_expiring_soon(target_id, expiring_in)
    if not self.active_songs[target_id] then
        return
    end
    expiring_in = expiring_in or self.expiring_duration
    local active_songs = self.active_songs[target_id]
    for song_record in active_songs:it() do
        local new_expire_time = math.min(song_record:get_expire_time(), os.time() + expiring_in)
        song_record:set_expire_time(new_expire_time)
        logger.notice("Setting expiration time of", res.spells[song_record:get_song_id()].name, "to", new_expire_time)
    end
end

-------
-- Sets all songs to expire soon for all party members.
function SongTracker:set_all_expiring_soon()
    local player = self.party:get_player()
    for party_member in list.extend(L{player}, self.party:get_party_members(false)):it() do
        self:set_expiring_soon(party_member:get_id(), self.expiring_duration)
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

    local party_member = self.party:get_party_member(target_id)

    logger.notice("Current buffs for", party_member:get_name(), "are", tostring(L(party_util.get_buffs(target_id)):map(function(buff_id) return res.buffs[buff_id].name  end)))

    local target_songs = (self.active_songs[target_id] or S{}):add(SongRecord.new(song_id, song_duration or self.job:get_song_duration(res.spells[song_id].name)))
    self.active_songs[target_id] = target_songs

    self:on_songs_changed():trigger(self, target_id, self.active_songs[target_id])

    logger.notice(party_member:get_name(), "gains the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
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

    local party_member = self.party:get_party_member(target_id)

    logger.notice("Current buffs for", party_member:get_name(), "are", tostring(L(party_util.get_buffs(target_id)):map(function(buff_id) return res.buffs[buff_id].name  end)))

    local target_songs = (self.active_songs[target_id] or S{}):filter(function(song_record) return song_record:get_song_id() ~= song_id  end)
    self.active_songs[target_id] = target_songs

    self:on_songs_changed():trigger(self, target_id, self.active_songs[target_id])

    logger.notice(party_member:get_name(), "loses the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
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
    local party_member = self.party:get_party_member(target_id)

    local song_buff_ids = S{}
    for song in songs:it() do
        local buff_id = song:get_spell().status
        if not buff_util.is_buff_active(buff_id, buff_ids) then
            self:on_lose_song(target_id, song:get_spell().id, song:get_spell().status)
        else
            song_buff_ids:add(buff_id)
        end
    end

    local buff_id_to_records = {}
    for buff_id in song_buff_ids:it() do
        buff_id_to_records[buff_id] = self:get_songs(target_id, buff_id)
    end

    for buff_id, song_records in pairs(buff_id_to_records) do
        local buff_count = buff_util.buff_count(buff_id, buff_ids)
        if song_records:length() > buff_count then
            logger.notice(party_member:get_name(), "has", buff_count, res.buffs[buff_id].name, "buffs but song records of", tostring(song_records:map(function(song) return res.spells[song:get_song_id()].name end)))
            local songs_to_remove = L(song_records):sort(function(song_record1, song_record2)
                return song_record1:get_expire_time() < song_record2:get_expire_time()
            end):slice(1, song_records:length() - buff_count)
            for song in songs_to_remove:it() do
                logger.notice("Overwriting", party_member:get_name().."'s", res.spells[song:get_song_id()].name)
                self:on_lose_song(target_id, song:get_song_id(), song:get_buff_id())
            end
        end
    end
end

-------
-- Prunes expired songs from the target.
-- @tparam number target_id Target id
function SongTracker:prune_expired_songs(target_id)
    if self.active_songs[target_id] then
        for song_record in self.active_songs[target_id]:it() do
            if song_record:is_expired() then
                self:on_lose_song(target_id, song_record:get_song_id(), song_record:get_buff_id())
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
    return songs_active:length() >= self:get_max_num_songs(target_id)
end

-------
-- Returns a target's songs.
-- @tparam number target_id Target id
-- @tparam number buff_id Filter by buff id (optional)
-- @treturn List Buff ids (see buffs.lua)
function SongTracker:get_songs(target_id, buff_id)
    local target_songs = S(self.active_songs[target_id]) or S{}
    if buff_id then
        return target_songs:filter(function(song_record) return song_record:get_buff_id() == buff_id end)
    else
        return target_songs
    end
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

-------
-- Returns the maximum number of songs that can be sung on a target.
-- @tparam number target_id Target id
-- @treturn number Maximum number of songs
function SongTracker:get_max_num_songs(target_id)
    local party_member = self.party:get_party_member(target_id)
    return self.job:get_max_num_songs(false, self.job:get_song_buff_ids(party_member:get_buff_ids()):length())
end

return SongTracker