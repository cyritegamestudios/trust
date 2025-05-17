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
SongTracker.__class = "SongTracker"

-- Event called when a song is < self.expiring_duration seconds from wearing off
function SongTracker:on_song_duration_warning()
    return self.song_duration_warning
end

-- Event called when active songs change
function SongTracker:on_songs_changed()
    return self.songs_changed
end

-- Event called when active songs change
function SongTracker:on_song_added()
    return self.song_added
end


-------
-- Default initializer for a new song tracker.
-- @tparam Player player Player entity
-- @tparam Party party Player's party
-- @tparam List dummy_songs List of dummy songs (see spell.lua)
-- @tparam List songs List of songs (see spell.lua)
-- @tparam List pianissimo_songs List of songs to be sung with pianissimo after songs (see spell.lua)
-- @treturn SongTracker A song tracker
function SongTracker.new(player, party, dummy_songs, songs, pianissimo_songs, job, expiring_duration)
    local self = setmetatable({}, SongTracker)
    self.party = party
    self.job = job
    self.active_songs = {}
    self.dispose_bag = DisposeBag.new()
    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function SongTracker:destroy()
    self.dispose_bag:destroy()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before songs will be tracked.
function SongTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    WindowerEvents.Spell.Finish:addAction(function(actor_id, spell_id, targets)
        if actor_id == self.party:get_player().id then
            if not self.job:is_bard_song(spell_id) then
                return
            end
            for _, target in pairs(targets) do
                local action = target.actions[1]
                if action then
                    if L{ 230, 266 }:contains(action.message) then
                        self:on_gain_song(target.id, spell_id, action.param)
                    end
                end
            end
        end
    end)

    local on_party_member_added = function(party_member)
        self.dispose_bag:add(party_member:on_gain_buff():addAction(function(p, buff_id)
            logger.notice(self.__class, p:get_name(), "gains the effect of pre", res.buffs[buff_id].name, p:get_buffs())
            if self.job:is_bard_song_buff(buff_id) then
                logger.notice(self.__class, p:get_name(), "gains the effect of", res.buffs[buff_id].name, p:get_buffs())
                self:prune_songs(p:get_id(), p:get_buff_ids())
            end
        end), party_member:on_gain_buff())

        self.dispose_bag:add(party_member:on_lose_buff():addAction(function(p, buff_id)
            if self.job:is_bard_song_buff(buff_id) then
                logger.notice(self.__class, p:get_mob().name.."'s", "effect of", res.buffs[buff_id].name, "wears off")
                self:prune_songs(p:get_id(), p:get_buff_ids())
            end
        end), party_member:on_lose_buff())

        self.dispose_bag:add(party_member:on_ko():addAction(function(p)
            self:reset(p:get_id())
        end), party_member:on_ko())
    end

    self.dispose_bag:add(self.party:on_party_member_added():addAction(on_party_member_added), self.party:on_party_member_added())
    self.dispose_bag:add(self.party:on_party_member_removed():addAction(function(p) self:reset(p:get_id()) end), self.party:on_party_member_removed())

    for party_member in self.party:get_party_members(true):it() do
        on_party_member_added(party_member)
    end

    --WindowerEvents.BuffDurationChanged:addAction(function(mob_id, buff_records)
    --    print('buffs changed', buff_records)
    --    for buff_record in buff_records:it() do
    --        print(res.buffs[buff_record:get_buff_id()].en, 'has', buff_record:get_time_remaining())
    --    end
    --end)
end

-------
-- Call when a target gains a song.
-- @tparam number target_id Target id
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam number song_duration (optional) Song duration, or job default if not specified
function SongTracker:on_gain_song(target_id, song_id, buff_id, song_duration)
    local party_member = self.party:get_party_member(target_id)
    if not party_member then
        return
    end

    local target_songs = (self.active_songs[party_member:get_id()] or S{}):add(SongRecord.new(song_id, song_duration or self.job:get_song_duration(res.spells[song_id].en)))
    self.active_songs[target_id] = target_songs

    print(self.__class, party_member:get_name(), "gains the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name, self.job:get_song_duration(res.spells[song_id].name))
end

-------
-- Call when a target loses a song.
-- @tparam number target_id Target id
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number buff_id Buff id (see buffs.lua)
function SongTracker:on_lose_song(target_id, song_id, buff_id)
    local party_member = self.party:get_party_member(target_id)

    local target_songs = (self.active_songs[target_id] or S{}):filter(function(song_record) return song_record:get_song_id() ~= song_id  end)
    self.active_songs[target_id] = target_songs

    print(self.__class, party_member:get_name(), "loses the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
end

-------
-- Removes songs from the song id list that are no longer active.
-- @tparam number target_id Target id
-- @tparam List songs List of songs (see Spell.lua)

-- @tparam List buff_ids The target's buff ids (see buffs.lua)
function SongTracker:prune_songs(target_id, buff_ids)
    -- This can happen for both player and party members, but for player you get buff records with durations (does this actually matter?)
    -- Cases for overriding songs:
    -- 1. Every song record has a buff_id in buff records, no-op
    -- 2. Buff ids are unique and song records are missing, prune these song records
    -- 3. Buff ids are not unique and song records with the same buff ids are missing, prune in FIFO order using time remaining

    local party_member = self.party:get_party_member(target_id)

    buff_ids = buff_ids or party_member:get_buff_ids()

    local songs = self.active_songs[party_member:get_id()]:map(function(s) return s:get_song() end)

    local song_buff_ids = S{}
    for song in songs:it() do
        local buff_id = song.status
        if not buff_util.is_buff_active(buff_id, buff_ids) then
            self:on_lose_song(target_id, song.id, song.status)
        else
            song_buff_ids:add(buff_id)
        end
    end

    local buff_id_to_records = {}
    for buff_id in song_buff_ids:it() do
        buff_id_to_records[buff_id] = self:get_songs(target_id, buff_id)
    end

    local song_records_to_remove = L{}
    for buff_id, song_records in pairs(buff_id_to_records) do
        local buff_count = buff_util.buff_count(buff_id, buff_ids)
        if buff_count == 0 then
            song_records_to_remove = song_records_to_remove + song_records
        elseif song_records:length() > buff_count then
            logger.notice(self.__class, party_member:get_name(), "has", buff_count, res.buffs[buff_id].name, "buffs but song records of", tostring(song_records:map(function(song) return res.spells[song:get_song_id()].name end)))
            local songs_to_remove = L(song_records):sort(function(song_record1, song_record2)
                return song_record1:get_expire_time() < song_record2:get_expire_time()
            end):slice(1, song_records:length() - buff_count)
            song_records_to_remove = song_records_to_remove + songs_to_remove
        end
    end
    for song in song_records_to_remove:it() do
        logger.notice(self.__class, "Overwriting", party_member:get_name().."'s", res.spells[song:get_song_id()].name)
        self:on_lose_song(target_id, song:get_song_id(), song:get_buff_id())
    end
end

-------
-- Returns a target's songs.
-- @tparam number target_id Target id
-- @tparam number buff_id Filter by buff id (optional)
-- @treturn List Song records
function SongTracker:get_songs(target_id, buff_id)
    local target_songs = S(self.active_songs[target_id]) or S{}
    if buff_id then
        return target_songs:filter(function(song_record) return song_record:get_buff_id() == buff_id end)
    else
        return target_songs
    end
end

-------
-- Resets the active songs for the list of party members, or all if none specified.
-- @tparam list party_member_ids Party member ids
function SongTracker:reset(party_member_ids)
    party_member_ids = party_member_ids or self.party:get_party_member_ids()
    for party_member_id in party_member_ids:it() do
        self.active_songs[party_member_id] = S{}
    end
end

return SongTracker