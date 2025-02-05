local BlockAction = require('cylibs/actions/block')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local logger = require('cylibs/logger/logger')
local res = require('resources')

local Singer = setmetatable({}, {__index = Role })
Singer.__index = Singer
Singer.__class = "Singer"

local SongTracker = require('cylibs/battle/song_tracker')

-- Event called when singing begins
function Singer:on_songs_begin()
    return self.songs_begin
end

-- Event called when all songs have been sung
function Singer:on_songs_end()
    return self.songs_end
end

function Singer.new(action_queue, dummy_songs, songs, pianissimo_songs, brd_job, state_var, sing_action_priority)
    local self = setmetatable(Role.new(action_queue, brd_job), Singer)

    self:set_dummy_songs(dummy_songs)
    self:set_songs(songs)
    self:set_pianissimo_songs(pianissimo_songs)

    self.state_var = state_var or state.AutoSongMode
    self.sing_action_priority = sing_action_priority or ActionPriority.default
    self.is_singing = false
    self.song_action_identifier = self.__class..'_sing_song'
    self.last_sing_time = os.time()
    self.brd_job = brd_job
    self.songs_begin = Event.newEvent()
    self.songs_end = Event.newEvent()
    self.dispose_bag = DisposeBag.new()
    self.debug = false

    self:validate_songs(dummy_songs, songs)

    return self
end

function Singer:validate_songs(dummy_songs, songs)
    for song in songs:it() do
        if song:get_job_names():empty() then
            addon_system_error(song:get_name()..' does not have any job names selected.')
            return false
        end
    end

    -- 1. Player knows all songs
    local unknown_songs = (dummy_songs + songs):filter(function(song)
        return not spell_util.knows_spell(song:get_spell().id)
    end):map(function(song) return song:get_name() end)
    if unknown_songs:length() > 0 then
        addon_system_error("Unknown songs: "..localization_util.commas(unknown_songs))
        return false
    end

    -- 2. Dummy songs and songs don't overlap
    local buffs_for_dummy_songs = S(dummy_songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end))
    local buffs_for_songs = S(songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end))

    if set.intersection(buffs_for_dummy_songs, buffs_for_songs):length() > 0 then
        addon_system_error("Dummy songs cannot give the same status effects as real songs.")
        return false
    end

    -- 3. There are 3 dummy songs and 5 songs
    if self:get_job():get_max_num_songs() > 2 and (dummy_songs:length() < 3 or songs:length() < 5) then
        addon_system_error("You must choose 3 valid dummy songs and 5 songs.")
        return false
    end

    return true
end


function Singer:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Singer:on_add()
    Role.on_add(self)

    self.song_target = self:get_party():get_player()

    self.song_tracker = SongTracker.new(self:get_player(), self:get_party(), self.dummy_songs, self.songs, self.pianissimo_songs, self.brd_job)
    self.song_tracker:monitor()

    self.dispose_bag:add(self.state_var:on_state_change():addAction(function(_, newValue)
        if newValue == 'Off' then
            self.is_singing = false
        end
    end), self.state_var:on_state_change())

    self.dispose_bag:add(addon_enabled:onValueChanged():addAction(function(_, isEnabled)
        if not isEnabled then
            self:set_is_singing(false)
        end
    end), addon_enabled:onValueChanged())

    self.dispose_bag:add(self.action_queue:on_action_start():addAction(function(_, a)
        if a:getidentifier() == self.song_action_identifier then
            self:set_is_singing(true)
        end
    end), self.action_queue:on_action_start())

    self.dispose_bag:add(self.song_tracker:on_song_added():addAction(
        function (_, target_id, song_id, buff_id)
            if self.state_var.value == 'Off' then
                return
            end
            self:check_songs()
        end), self.song_tracker:on_song_added())

    self.dispose_bag:addAny(L{ self.song_tracker })
end

function Singer:set_is_singing(is_singing)
    if self.is_singing == is_singing then
        return
    end
    self.is_singing = is_singing
    if self.is_singing then
        self:on_songs_begin():trigger(self)
    else
        self:on_songs_end():trigger(self)
    end
end

function Singer:get_is_singing()
    return self.is_singing
end

function Singer:tic(new_time, old_time)
    logger.notice(self.__class, "tic", "song_delay", self.brd_job:get_song_delay(), "seconds", "("..(self:get_last_tic_time() - self.last_sing_time), "seconds since last sing)")

    if self.state_var.value == 'Off'
            or (self:get_last_tic_time() - self.last_sing_time) <= self.brd_job:get_song_delay()
            or self:get_player():is_moving() then
        return
    end
    self.song_tracker:tic(new_time, old_time)

    self:check_songs()
end

function Singer:assert_num_songs(party_member)
    local max_num_songs = self.song_tracker:get_max_num_songs(party_member:get_id())

    logger.notice(self.__class, "assert_num_songs", "maximum number of songs is", max_num_songs)

    local current_num_songs = L(self.song_tracker:get_songs(party_member:get_id())):length()
    local current_num_song_buffs = self.brd_job:get_song_buff_ids(party_member:get_buff_ids()):length()

    if current_num_songs ~= current_num_song_buffs then
        logger.error(self.__class, "assert_num_songs", "expected", current_num_song_buffs, "songs but got", current_num_songs, "song records")

        local songs_from_records = L(self.song_tracker:get_songs(party_member:get_id())):map(function(song_record) return res.spells[song_record:get_song_id()].en end)
        local song_buff_names = self.brd_job:get_song_buff_ids(party_member:get_buff_ids()):map(function(buff_id) return res.buffs[buff_id].en  end)

        logger.error(self.__class, "assert_num_songs", "song records are", tostring(songs_from_records), "but buffs are", tostring(song_buff_names))
    end
end

function Singer:check_songs()
    self.action_queue:cleanup()

    if self:get_player():is_moving() or self.action_queue:has_action(self.song_action_identifier) then
        return
    end

    if not self:validate_songs(self.dummy_songs, self.songs) then
        self:get_party():add_to_chat(self:get_party(), "I can't sing until you fix these issues!", self.__class..'_validate', 10)
        return
    end

    local player = self:get_party():get_player()
    local has_more_songs = false

    self:assert_num_songs(player)

    local party_members = self:get_party():get_party_members(true, 20):filter(function(p) return p:get_id() ~= self.song_target:get_id()  end)

    -- 1. Determine the singer's songs:
    --    a. If all party members have their merged songs, set songs to merged songs.
    --    b. If >= 1 party members are missing a song and the singer *does not* have all of their merged songs, set songs to main songs.
    --    c. If >= 1 party members are missing a song and the singer *does* have all of their merged songs, set songs to merged songs.
    -- 2. If singer is missing a song, sing the song.
    --    a. If singer's songs are merged songs, use pianissimo.
    --    b. If singer's songs are main songs, do not use pianissimo.
    -- 3. If party member is missing a song, sing song with pianissimo.

    -- Song target songs
    local song_target_songs, is_merged_songs = self:get_self_merged_songs(party_members)

    local next_song = self:get_next_song(self.song_target, self.dummy_songs, song_target_songs)
    if next_song then
        local allow_pianissimo = is_merged_songs and not self.song_tracker:is_expiring_soon(self.song_target:get_id(), song_target_songs)
        self:sing_song(next_song, self.song_target:get_mob().index, self:should_nitro(), allow_pianissimo)
        return
    end

    -- Party member songs
    for party_member in list.extend(L{}, party_members):it() do
        if party_member:is_alive() then
            local next_song = self:get_next_song(party_member, self.dummy_songs, self:get_merged_songs(party_member))
            if next_song then
                has_more_songs = true
                self:sing_song(next_song, party_member:get_mob().index, self:should_nitro())
                if party_member:get_id() == self.song_target:get_id() then
                    return
                end
            end
        end
    end
    if not has_more_songs then
        self:set_is_singing(false)
    end
end

function Singer:get_next_song(party_member, dummy_songs, songs)
    if party_member:get_mob() == nil or party_member:get_mob().distance:sqrt() > 20  then
        return nil
    end

    local song_target_id = party_member:get_mob().id
    local buff_ids = L(party_member:get_buff_ids())

    logger.notice(self.__class, "get_next_song", party_member:get_mob().name, songs:map(function(song) return song:get_spell().en end))

    local current_num_songs = self.job:get_song_buff_ids(buff_ids):length()
    local base_num_songs = 2
    if self.job:is_clarion_call_active() then
        base_num_songs = 3
    end

    if current_num_songs < songs:length() then
        if current_num_songs < base_num_songs or self.song_tracker:has_any_song(song_target_id, dummy_songs:map(function(song) return song:get_spell().id end), buff_ids) then
            for song in songs:it() do
                if not self.song_tracker:has_song(song_target_id, song:get_spell().id, buff_ids) then
                    return song
                end
            end
        else
            for song in dummy_songs:it() do
                if not self.song_tracker:has_song(song_target_id, song:get_spell().id, buff_ids) then
                    return song
                end
            end
        end
    else
        for song in songs:it() do
            if not self.song_tracker:has_song(song_target_id, song:get_spell().id, buff_ids) and spell_util.can_cast_spell(song:get_spell().id) then
                return song
            elseif self.song_tracker:is_expiring_soon(song_target_id, L{ song }) then
                logger.notice(self.__class, "get_next_song", "resinging", song:get_spell().en)
                return song
            end
        end
    end
    return nil
end

function Singer:sing_song(song, target_index, should_nitro, allow_self_pianissimo)
    local action_identifier = self.song_action_identifier-- 'singer_sing_song_'..song:get_spell().en

    self.action_queue:cleanup()

    if spell_util.can_cast_spell(song:get_spell().id) and not self.action_queue:has_action(action_identifier) then
        --self:set_is_singing(true)

        local actions = L{}
        local conditions = L{}
        local extra_duration = 0

        if self:get_player():is_moving() then
            actions:append(BlockAction.new(function()
                windower.ffxi.run(false)
            end), 'stop_moving')
            actions:append(WaitAction.new(0, 0, 0, 0.5))
        end

        self.last_sing_time = self:get_last_tic_time()

        local job_abilities = L{}
        if should_nitro then
            self.song_tracker:set_all_expiring_soon()
            job_abilities = self:get_nitro_abilities()
            extra_duration = extra_duration + 5.5
            actions:append(WaitAction.new(0, 0, 0, 1.5))
        end

        local job_abilities = job_abilities:extend(song:get_job_abilities():copy())
        if not allow_self_pianissimo and target_index == windower.ffxi.get_player().index and self.song_target:get_mob().index == windower.ffxi.get_player().index then
            if buff_util.is_buff_active(buff_util.buff_id('Pianissimo')) then
                logger.error(self.__class, "sing_song", "attempting to sing a song on self but Pianissimo is active")
                actions:append(BlockAction.new(function()
                    buff_util.cancel_buff(buff_util.buff_id('Pianissimo'))
                end), 'cancel_pianissimo', 'Cancelling Pianissimo')
            end
        else
            if self.song_target:get_mob().index ~= target_index or allow_self_pianissimo then
                if self:get_job():knows_job_ability('Pianissimo') then
                    local pianissimo_recast = self:get_job():get_job_ability_cooldown('Pianissimo')
                    if pianissimo_recast > 0 then
                        coroutine.schedule(function()
                            self:check_songs()
                        end, pianissimo_recast + 0.25)
                        return false
                    end
                    if not S(job_abilities):contains('Pianissimo') then
                        job_abilities:append('Pianissimo')
                    end
                    conditions:append(HasBuffCondition.new('Pianissimo', windower.ffxi.get_player().index))
                end
            end
        end
        for job_ability_name in job_abilities:it() do
            local job_ability = res.job_abilities:with('en', job_ability_name)
            if job_ability and not buff_util.is_buff_active(job_ability.status) and not buff_util.conflicts_with_buffs(job_ability.status, self:get_party():get_player():get_buff_ids()) then
                if job_util.can_use_job_ability(job_ability_name) then
                    actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                    actions:append(WaitAction.new(0, 0, 0, 1.5))
                end
            end
        end

        local song_target_index = target_index
        if target_index == self.song_target:get_mob().index then
            song_target_index = windower.ffxi.get_player().index
        end

        local spell_action = SpellAction.new(0, 0, 0, song:get_spell().id, song_target_index, self:get_player(), conditions)
        actions:append(spell_action)
        actions:append(WaitAction.new(0, 0, 0, 2))

        local sing_action = SequenceAction.new(actions, action_identifier, true)
        sing_action.max_duration = 8 + extra_duration
        sing_action.priority = ActionPriority.highest

        self.action_queue:push_action(sing_action, true)

        logger.notice(self.__class, "sing_song", "singing", res.spells[song:get_spell().id].name, "on", windower.ffxi.get_mob_by_index(target_index).name)

        return true
    end
    return false
end

function Singer:should_nitro()
    if state.AutoNitroMode.value == 'Auto' and self.brd_job:is_nitro_ready() then
        -- NOTE: this check doesn't work anymore because nitro job abilities are being added
        -- directly to the spell action
        if self.action_queue:has_action('nitro') then
            return false
        end

        local player = self:get_party():get_player()
        local buff_ids = L(player:get_buff_ids())
        local songs = self:get_merged_songs(player)

        local total_num_songs = self.song_tracker:get_num_songs(player:get_mob().id, buff_ids)
        if total_num_songs == 0 then
            logger.notice(self.__class, 'should_nitro', 'using nitro', 'no songs')
            return true
        end

        local total_num_active_songs = self.song_tracker:get_num_songs(player:get_mob().id, buff_ids, songs)
        if total_num_active_songs == self.brd_job:get_max_num_songs() and self.song_tracker:is_expiring_soon(player:get_mob().id, songs) then
            logger.notice(self.__class, 'should_nitro', 'using nitro', 'all songs')
            return true
        end

        if total_num_songs > 0 and total_num_active_songs == 0 then
            logger.notice(self.__class, 'should_nitro', 'using nitro', 'wrong songs')
            return true
        end
    end
    return false
end

function Singer:get_nitro_abilities()
    local player = self:get_party():get_player()

    local job_ability_names = L{}

    if state.AutoClarionCallMode.value == 'Auto' and self.brd_job:is_clarion_call_ready() then
        local current_num_songs = self.song_tracker:get_num_songs(player:get_mob().id, L(player:get_buff_ids()))
        if current_num_songs < self.brd_job:get_max_num_songs(true) then
            job_ability_names:append('Clarion Call')

            logger.notice(self.__class, "nitro", "using Clarion Call")
            logger.notice(self.__class, "nitro", "current songs for", player:get_mob().name, "are", self.song_tracker:get_songs(player:get_id(), L(player:get_buff_ids())):map(function(song_record) return res.spells[song_record:get_song_id()].en  end))
        end
    end

    job_ability_names:append('Nightingale')
    job_ability_names:append('Troubadour')

    return job_ability_names
end

function Singer:nitro()
    local player = self:get_party():get_player()

    self.song_tracker:set_all_expiring_soon()

    local actions = L{
        WaitAction.new(0, 0, 0, 1.5)
    }

    if state.AutoClarionCallMode.value == 'Auto' and self.brd_job:is_clarion_call_ready() then
        local current_num_songs = self.song_tracker:get_num_songs(player:get_mob().id, L(player:get_buff_ids()))
        if current_num_songs < self.brd_job:get_max_num_songs(true) then
            actions:append(JobAbilityAction.new(0, 0, 0, 'Clarion Call'))
            actions:append(WaitAction.new(0, 0, 0, 1.5))

            logger.notice(self.__class, "nitro", "using Clarion Call")
            logger.notice(self.__class, "nitro", "current songs for", player:get_mob().name, "are", self.song_tracker:get_songs(player:get_id(), L(player:get_buff_ids())):map(function(song_record) return res.spells[song_record:get_song_id()].en  end))
        end
    end

    actions:append(JobAbilityAction.new(0, 0, 0, 'Nightingale'))
    actions:append(WaitAction.new(0, 0, 0, 1.5))
    actions:append(JobAbilityAction.new(0, 0, 0, 'Troubadour'))
    actions:append(WaitAction.new(0, 0, 0, 1.5))

    local nitro_action = SequenceAction.new(actions, 'nitro')
    nitro_action.max_duration = 8
    nitro_action.priority = ActionPriority.highest

    self.action_queue:push_action(nitro_action, true)
end

function Singer:get_self_merged_songs(party_members)
    local merged_songs = self:get_merged_songs(self.song_target)

    local max_num_songs = self.song_tracker:get_max_num_songs(self.song_target:get_id())
    local songs = self.songs:slice(1, max_num_songs):reverse()

    if self.song_tracker:is_expiring_soon(self.song_target:get_id(), songs) or self:should_nitro() then
        return songs, false
    end

    local party_members_missing_songs = party_members:filter(function(p)
        return p:is_alive() and self:get_next_song(p, self.dummy_songs, self:get_merged_songs(p)) ~= nil
    end)
    -- If all party members have their merged songs, set songs to merged songs.
    if party_members_missing_songs:length() == 0 then
        return merged_songs, true
    else
        local buff_ids = L(self.song_target:get_buff_ids())
        -- If >= 1 party members are missing a song and the singer *does not* have all of their merged songs, set songs to main songs.
        if self.song_tracker:has_all_songs(self.song_target:get_id(), merged_songs:map(function(song) return song:get_spell().id end), buff_ids) then
            return merged_songs, true
        -- If >= 1 party members are missing a song and the singer *does* have all of their merged songs, set songs to merged songs.
        else
            return songs, false
        end
    end
end

function Singer:get_merged_songs(party_member, max_num_songs)
    -- 1. Determine the singer's songs:
    --    a. If all party members have their merged songs, set songs to merged songs.
    --    b. If >= 1 party members are missing a song and the singer *does not* have all of their merged songs, set songs to main songs.
    --    c. If >= 1 party members are missing a song and the singer *does* have all of their merged songs, set songs to merged songs.
    -- 2. If singer is missing a song, sing the song.
    --    a. If singer's songs are merged songs, use pianissimo.
    --    b. If singer's songs are main songs, do not use pianissimo.
    -- 3. If party member is missing a song, sing song with pianissimo.
    local max_num_songs = max_num_songs or self.song_tracker:get_max_num_songs(party_member:get_id())

    logger.notice(self.__class, "get_merged_songs", "maximum number of songs for", party_member:get_name(), "is", max_num_songs)

    local pianissimo_songs = self.pianissimo_songs:filter(function(song)
        return song:get_job_names():contains(party_member:get_main_job_short())
    end)

    local all_songs = L{}
    if not party_member:is_trust() and state.AutoPianissimoMode.value == 'Merged' then
        local songs = self.songs:filter(function(song)
            return not song:get_job_names() or song:get_job_names():contains(party_member:get_main_job_short()) or party_member:get_main_job_short() == 'NON'
        end)
        all_songs = pianissimo_songs:extend(songs)
        all_songs = all_songs:slice(1, math.min(all_songs:length(), max_num_songs)):reverse()
    else
        all_songs = pianissimo_songs
    end

    if all_songs:length() == 0 then
        logger.error(self.__class, "get_merged_songs", "no valid songs found for", party_member:get_name())
    end

    return all_songs or L{}
end

function Singer:set_dummy_songs(dummy_songs)
    self.dummy_songs = (dummy_songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
end

function Singer:get_dummy_songs()
    return self.dummy_songs
end

function Singer:set_songs(songs)
    self.songs = (songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id)  end)
end

function Singer:get_songs()
    return self.songs
end

function Singer:set_pianissimo_songs(pianissimo_songs)
    self.pianissimo_songs = (pianissimo_songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id)  end)
end

function Singer:get_pianissimo_songs()
    return self.pianissimo_songs
end

function Singer:set_song_target(party_member)
    self.song_target = party_member or self:get_party():get_player()
end

function Singer:allows_duplicates()
    return false
end

function Singer:get_type()
    return "singer"
end

return Singer