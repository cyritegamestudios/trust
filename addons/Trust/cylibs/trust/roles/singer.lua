local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local logger = require('cylibs/logger/logger')
local res = require('resources')

local Singer = setmetatable({}, {__index = Role })
Singer.__index = Singer

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
    local self = setmetatable(Role.new(action_queue), Singer)

    self:set_dummy_songs(dummy_songs)
    self:set_songs(songs)
    self:set_pianissimo_songs(pianissimo_songs)

    self.state_var = state_var or state.AutoSongMode
    self.sing_action_priority = sing_action_priority or ActionPriority.default
    self.is_singing = false
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
    local buffs_for_dummy_songs = S(dummy_songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end))
    local buffs_for_songs = S(songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end))

    if set.intersection(buffs_for_dummy_songs, buffs_for_songs):length() > 0 then
        error("Dummy songs cannot give the same status effects as real songs.")
    end
    assert(set.intersection(buffs_for_dummy_songs, buffs_for_songs):length() == 0, "Dummy songs cannot give the same status effects as real songs.")
end


function Singer:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Singer:on_add()
    Role.on_add(self)

    self.song_tracker = SongTracker.new(self:get_player(), self.dummy_songs, self.songs, self.pianissimo_songs, self.brd_job)
    self.song_tracker:monitor()

    self.dispose_bag:add(self.state_var:on_state_change():addAction(function(_, newValue)
        if newValue == 'Off' then
            self.is_singing = false
        end
    end), self.state_var:on_state_change())

    self.dispose_bag:addAny(L{ self.song_tracker })
end

function Singer:target_change(target_index)
    Role.target_change(self, target_index)
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
    logger.notice("Song delay is", self.brd_job:get_song_delay(), "seconds")

    if self.state_var.value == 'Off'
            or (os.time() - self.last_sing_time) <= self.brd_job:get_song_delay()
            or self:get_player():is_moving() then
        return
    end
    self.song_tracker:tic(new_time, old_time)

    self:check_songs()
end

function Singer:check_songs()
    local player = self:get_party():get_player()

    logger.notice("Maximum number of songs is", self.brd_job:get_max_num_songs())

    if self:should_nitro() then
        self:nitro()
        return
    end

    for party_member in list.extend(L{player}, self:get_party():get_party_members(false)):it() do
        if party_member:is_alive() then
            if party_member:is_trust() then -- can potentially remove since AlterEgo has its own buff_id list now
                self.song_tracker:prune_expired_songs(party_member:get_id())
            end
            local next_song = self:get_next_song(party_member, self.dummy_songs, self:get_merged_songs(party_member))
            if next_song then
                if self.dummy_songs:contains(next_song) then
                    windower.send_command('gs c set ExtraSongsMode Dummy')
                else
                    windower.send_command('gs c set ExtraSongsMode None')
                end
                self:sing_song(next_song, party_member:get_mob().index)
                return
            end
        end
    end

    self:set_is_singing(false)
end

function Singer:get_next_song(party_member, dummy_songs, songs)
    local song_target_id = party_member:get_mob().id
    local buff_ids = L(party_member:get_buff_ids())

    logger.notice("Songs for", party_member:get_mob().name, songs:map(function(song) return song:get_spell().name end))

    local total_num_songs = self.song_tracker:get_num_songs(song_target_id, buff_ids)
    if total_num_songs < 2 then
        for song in songs:it() do
            if not self.song_tracker:has_song(song_target_id, song:get_spell().id, buff_ids) then
                return song
            end
        end
    else
        if total_num_songs < self.brd_job:get_max_num_songs() then
            for song in dummy_songs:it() do
                if not self.song_tracker:has_song(song_target_id, song:get_spell().id, buff_ids) then
                    return song
                end
            end
        else
            local total_num_active_songs = self.song_tracker:get_num_songs(song_target_id, buff_ids, songs)
            for song in songs:it() do
                if total_num_active_songs < self.brd_job:get_max_num_songs() then
                    if not self.song_tracker:has_song(song_target_id, song:get_spell().id, buff_ids) then
                        return song
                    end
                else
                    if self.song_tracker:is_expiring_soon(song_target_id, L{ song }) then
                        logger.notice("Resinging", song:get_spell().name)
                        return song
                    end
                end
            end
        end
    end
    return nil
end

function Singer:sing_song(song, target_index)
    if spell_util.can_cast_spell(song:get_spell().id) then
        self:set_is_singing(true)

        local actions = L{}

        self.last_sing_time = os.time()

        local job_abilities = S(song:get_job_abilities():copy())
        if target_index ~= windower.ffxi.get_player().index then
            if not job_util.can_use_job_ability('Pianissimo') then
                return false
            end
            job_abilities:add('Pianissimo')
        end
        for job_ability_name in job_abilities:it() do
            local job_ability = res.job_abilities:with('en', job_ability_name)
            if job_ability and not buff_util.is_buff_active(job_ability.status) then
                if job_util.can_use_job_ability(job_ability_name) then
                    actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                    actions:append(WaitAction.new(0, 0, 0, 1.5))
                end
            end
        end

        actions:append(SpellAction.new(0, 0, 0, song:get_spell().id, target_index, self:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))

        local sing_action = SequenceAction.new(actions, 'singer_'..song:get_spell().en)
        sing_action.priority = ActionPriority.highest

        self.action_queue:push_action(sing_action, true)

        return true
    end
    return false
end

function Singer:should_nitro()
    if self.brd_job:is_nitro_ready() then
        local player = self:get_party():get_player()
        local buff_ids = L(player:get_buff_ids())
        local songs = self:get_merged_songs(player)

        local total_num_songs = self.song_tracker:get_num_songs(player:get_mob().id, buff_ids)
        if total_num_songs == 0 then
            logger.notice("Using nitro (no songs)")
            return true
        end

        local total_num_active_songs = self.song_tracker:get_num_songs(player:get_mob().id, buff_ids, songs)
        if total_num_active_songs == self.brd_job:get_max_num_songs() and self.song_tracker:is_expiring_soon(player:get_mob().id, songs) then
            logger.notice("Using nitro (all songs)")
            return true
        end
    end
    return false
end

function Singer:nitro()
    local player = self:get_party():get_player()

    self.song_tracker:set_expiring_soon(player:get_mob().id)

    local actions = L{
        WaitAction.new(0, 0, 0, 1.5)
    }

    if state.AutoClarionCallMode.value == 'Auto' and self.brd_job:is_clarion_call_ready() then
        local buff_ids = L(player:get_buff_ids())
        local total_num_songs = self.song_tracker:get_num_songs(player:get_mob().id, buff_ids)
        if total_num_songs < self.brd_job:get_max_num_songs() + 1 then
            actions:append(JobAbilityAction.new(0, 0, 0, 'Clarion Call'))
            actions:append(WaitAction.new(0, 0, 0, 1.5))
        end
    end

    actions:append(JobAbilityAction.new(0, 0, 0, 'Nightingale'))
    actions:append(WaitAction.new(0, 0, 0, 1.5))
    actions:append(JobAbilityAction.new(0, 0, 0, 'Troubadour'))
    actions:append(WaitAction.new(0, 0, 0, 1))

    local nitro_action = SequenceAction.new(actions, 'nitro')
    nitro_action.priority = ActionPriority.highest

    self.action_queue:push_action(nitro_action, true)
end

function Singer:get_merged_songs(party_member)
    local max_num_songs = self.brd_job:get_max_num_songs()
    if party_member:get_mob().id == windower.ffxi.get_player().id then
        return self.songs:slice(1, max_num_songs)
    end
    local pianissimo_songs = self.pianissimo_songs:filter(function(song) return song:get_job_names():contains(party_member:get_main_job_short()) end)
    local all_songs = self.songs:slice(1, max_num_songs):extend(pianissimo_songs):reverse()
    all_songs = all_songs:slice(1, max_num_songs)

    if all_songs:length() == 0 then
        logger.error("No valid songs found for", party_member:get_name())
    end

    return all_songs
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

function Singer:allows_duplicates()
    return false
end

function Singer:get_type()
    return "singer"
end

return Singer