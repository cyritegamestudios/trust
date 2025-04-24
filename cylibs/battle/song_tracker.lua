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
    local self = setmetatable({
        action_events = {};
        player = player;
        party = party;
        dummy_songs = dummy_songs;
        pianissimo_songs = pianissimo_songs;
        songs = songs;
        job = job;
        active_songs = {};
        expiring_duration = expiring_duration or 260;
        last_expiration_check = os.time();
    }, SongTracker)

    self.dispose_bag = DisposeBag.new()
    self.song_duration_warning = Event.newEvent()
    self.songs_changed = Event.newEvent()
    self.song_added = Event.newEvent()

    local has_songs = false
    local all_songs = L{}:extend(dummy_songs):extend(songs):extend(pianissimo_songs)
    for party_member in party:get_party_members(true, 30):it() do
        for song in all_songs:it() do
            local buff_id = res.buffs:with('id', song:get_spell().status).id
            if buff_util.is_buff_active(buff_id, party_member:get_buff_ids()) then
                has_songs = true
                self:on_gain_song(party_member:get_id(), song:get_spell().id, buff_id)
            end
        end
        logger.notice(self.__class, party_member:get_name().."'s", "songs are", self:get_songs(party_member:get_id()):map(function(song_record) return res.spells[song_record:get_song_id()].name end))
    end

    if has_songs then
        party:add_to_chat(self.party:get_player(), "It looks like there are already some active songs. I'll try my best to figure out what they are. Use // trust brd clear if I got it wrong and you want me to resing!")

        if WindowerEvents.can_replay_last_event(WindowerEvents.BuffDurationChanged) then
            local action_id = WindowerEvents.BuffDurationChanged:addAction(function(_, buff_records)
                local song_records = L(buff_records:filter(function(buff_record)
                    return self.job:is_bard_song_buff(buff_record:get_buff_id())
                end)):sort(function(buff_record_1, buff_record_2)
                    return buff_record_1:get_expire_time() < buff_record_2:get_expire_time()
                end)
                if song_records:length() > 0 then
                    local min_song_duration = math.max(song_records[1]:get_time_remaining(), 0)

                    local active_songs = all_songs:filter(function(song)
                        return self:has_song(self.party:get_player().id, song:get_spell().id)
                    end)
                    for song in active_songs:it() do
                        self:update_song_duration(self.party:get_player().id, song:get_spell().id, min_song_duration)
                    end
                else
                    self:set_expiring_soon(windower.ffxi.get_player().id)
                end
                return false
            end)
            WindowerEvents.BuffDurationChanged:setActionTriggerLimit(action_id, 1)

            WindowerEvents.replay_last_event(WindowerEvents.BuffDurationChanged)
        else
            self:set_expiring_soon(windower.ffxi.get_player().id)
        end
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
    self.song_added:removeAllActions()
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
                if song and song.type == 'BardSong' and song.status and self.job:is_bard_song_buff(song.status) then
                    for _, target in pairs(targets) do
                        local action = target.actions[1]
                        if action then
                            self.last_song_id = song_id
                            self:check_instrument(song_id, self.party:get_player():get_ranged_weapon_id())
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

    local on_party_member_added = function(party_member)
        self.dispose_bag:add(party_member:on_gain_buff():addAction(function(p, buff_id)
            logger.notice(self.__class, p:get_name(), "gains the effect of pre", res.buffs[buff_id].name, p:get_buffs())
            if self.job:is_bard_song_buff(buff_id) then
                logger.notice(self.__class, p:get_name(), "gains the effect of", res.buffs[buff_id].name, p:get_buffs())
                self:prune_all_songs(p:get_id(), p:get_buff_ids())
                if self.last_song_id and res.spells[self.last_song_id].status == buff_id then
                    self:on_song_added():trigger(self, p:get_id(), self.last_song_id, buff_id)
                end
            end
        end), party_member:on_gain_buff())

        self.dispose_bag:add(party_member:on_lose_buff():addAction(function(p, buff_id)
            print(self.__class, 'losing', res.buffs[buff_id].en)
            if self.job:is_bard_song_buff(buff_id) then
                logger.notice(self.__class, p:get_mob().name.."'s", "effect of", res.buffs[buff_id].name, "wears off")
                self:prune_all_songs(p:get_id(), p:get_buff_ids())
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
end

function SongTracker:check_instrument(song_id, instrument_id)
    if not self.diagnostics_enabled then
        return
    end
    local dummy_song_ids = S(self.dummy_songs:map(function(dummy_song) return dummy_song:get_ability_id() end))
    if dummy_song_ids:contains(song_id) then
        if not self.job:get_extra_song_instrument_ids():contains(instrument_id) then
            self.party:add_to_chat(self.party:get_player(), "It looks like I'm not singing "..res.spells[song_id].en.." with an instrument that grants me an extra song. Can you look at my GearSwap?", nil, nil, true)
        end
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
            local target = windower.ffxi.get_mob_by_id(target_id) or { name = 'Unknown'}
            for song_record in song_records:it() do
                logger.notice(self.__class, target.name.."'s", res.spells[song_record:get_song_id()].name, "has", song_record:get_expire_time() - os.time(), "seconds remaining")
                if song_record:is_expired() then
                    self:on_lose_song(target_id, song_record:get_song_id(), song_record:get_buff_id())
                    logger.notice(self.__class, target.name.."'s", res.spells[song_record:get_song_id()].name, "is expired")
                elseif song_record:get_expire_time() - os.time() < self.expiring_duration then
                    self:on_song_duration_warning():trigger(song_record)
                    logger.notice(self.__class, target.name.."'s", res.spells[song_record:get_song_id()].name, "is expiring soon")
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
        logger.notice(self.__class, "Setting expiration time of", res.spells[song_record:get_song_id()].name, "to", new_expire_time)
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
function SongTracker:reset(target_id)
    self.last_song_id = nil

    local reset_all = target_id == nil
    for t_id, target_songs in pairs(self.active_songs) do
        if reset_all or target_id == t_id then
            self:on_songs_changed():trigger(self, t_id, target_songs)
        end
    end
    if reset_all then
        self.active_songs = {}
    else
        self.active_songs[target_id] = S{}
    end
end

-------
-- Call when a target gains a song.
-- @tparam number target_id Target id
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number buff_id Buff id (see buffs.lua)
-- @tparam number song_duration (optional) Song duration, or job default if not specified
function SongTracker:on_gain_song(target_id, song_id, buff_id, song_duration)
    local party_member = self.party:get_party_member(target_id)

    if self:has_song(target_id, song_id) then
        self:on_lose_song(target_id, song_id, buff_id)
    end

    logger.notice(self.__class, "Current buffs for", party_member:get_name(), "are", tostring(L(party_util.get_buffs(target_id)):map(function(buff_id) return res.buffs[buff_id].en  end)))

    local target_songs = (self.active_songs[target_id] or S{}):add(SongRecord.new(song_id, song_duration or self.job:get_song_duration(res.spells[song_id].en)))
    self.active_songs[target_id] = target_songs

    self:on_songs_changed():trigger(self, target_id, self.active_songs[target_id])

    logger.notice(self.__class, party_member:get_name(), "gains the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
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
    print('lose song', res.spells[song_id].en)
    local party_member = self.party:get_party_member(target_id)

    logger.notice(self.__class, "Current buffs for", party_member:get_name(), "are", tostring(L(party_util.get_buffs(target_id)):map(function(buff_id) return res.buffs[buff_id].name  end)))

    local target_songs = (self.active_songs[target_id] or S{}):filter(function(song_record) return song_record:get_song_id() ~= song_id  end)
    self.active_songs[target_id] = target_songs

    self:on_songs_changed():trigger(self, target_id, self.active_songs[target_id])

    logger.notice(self.__class, party_member:get_name(), "loses the effect of "..res.buffs[buff_id].name.." from "..res.spells[song_id].name)
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

    buff_ids = buff_ids or party_member:get_buff_ids()

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
            logger.notice(self.__class, party_member:get_name(), "has", buff_count, res.buffs[buff_id].name, "buffs but song records of", tostring(song_records:map(function(song) return res.spells[song:get_song_id()].name end)))
            local songs_to_remove = L(song_records):sort(function(song_record1, song_record2)
                return song_record1:get_expire_time() < song_record2:get_expire_time()
            end):slice(1, song_records:length() - buff_count)
            for song in songs_to_remove:it() do
                logger.notice(self.__class, "Overwriting", party_member:get_name().."'s", res.spells[song:get_song_id()].name)
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

function SongTracker:update_song_duration(target_id, song_id, song_duration)
    if self.active_songs[target_id] then
        for song_record in self.active_songs[target_id]:it() do
            if song_record:get_song_id() == song_id then
                logger.notice(self.__class, 'update_song_duration', res.spells[song_id].en, song_duration, 'old_duration', song_record:get_time_remaining())
                song_record:set_song_duration(song_duration)
                return
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
    if not party_member:is_trust() then
        return self.job:get_max_num_songs(false, self.job:get_song_buff_ids(party_member:get_buff_ids()):length())
    else
        return self.job:get_max_num_songs(false, self.job:get_song_buff_ids(self.party:get_player():get_buff_ids()):length())
    end
end

return SongTracker