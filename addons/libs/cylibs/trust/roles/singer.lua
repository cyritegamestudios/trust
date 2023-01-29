local res = require('resources')

local Singer = setmetatable({}, {__index = Role })
Singer.__index = Singer

local SongTracker = require('cylibs/battle/song_tracker')

function Singer.new(action_queue, dummy_songs, songs, pianissimo_songs, brd_job, state_var, sing_action_priority)
    local self = setmetatable(Role.new(action_queue), Singer)

    self:set_dummy_songs(dummy_songs)
    self:set_songs(songs)
    self:set_pianissimo_songs(pianissimo_songs)
    self.state_var = state_var or state.AutoSongMode
    self.sing_action_priority = sing_action_priority or ActionPriority.default
    self.last_sing_time = os.time()
    self.brd_job = brd_job
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

    self.song_tracker:destroy()
end

function Singer:on_add()
    Role.on_add(self)

    self.song_tracker = SongTracker.new(self:get_player(), self.dummy_songs, self.songs, self.pianissimo_songs, self.brd_job)
    self.song_tracker:monitor()
    self.song_tracker:on_song_duration_warning():addAction(function(song_record)
        if self.debug then
            print(res.spells:with('id', song_record:get_song_id()).en..' is expiring soon')
        end
        self:resing_song(song_record:get_song_id())
    end)
end

function Singer:target_change(target_index)
    Role.target_change(self, target_index)
end

function Singer:tic(new_time, old_time)
    if self.state_var.value == 'Off'
            or (os.time() - self.last_sing_time) < 7 then
        return
    end
    self.song_tracker:tic(new_time, old_time)

    self:check_songs()
end

function Singer:check_songs()
    if self:get_player():is_moving() then
        return
    end

    if not self:sing_next_song() then
        self:sing_next_piannisimo_song()
    end
end

function Singer:sing_next_song()
    local song_target_id = windower.ffxi.get_player().id
    local player_buff_ids = L(windower.ffxi.get_player().buffs)

    local song_ids = self.songs:map(function(spell) return spell:get_spell().id end)
    local dummy_song_ids = self.dummy_songs:map(function(spell) return spell:get_spell().id  end)

    if not self.song_tracker:has_all_songs(song_target_id, dummy_song_ids, player_buff_ids)
            and (not self.song_tracker:has_any_song(song_target_id, song_ids, player_buff_ids) or self.song_tracker:get_num_songs(song_target_id, player_buff_ids) < self.brd_job:get_max_num_songs()) then
        -- Get next dummy song
        for song in self.dummy_songs:it() do
            if not self.song_tracker:has_song(song_target_id, song:get_spell().id, player_buff_ids) then
                self:sing_song(song)
                return true
            end
        end
    elseif self.song_tracker:get_num_songs(song_target_id, player_buff_ids) == self.brd_job:get_max_num_songs() then
        -- Already has the maximum number of real songs
        if self.song_tracker:get_num_songs(song_target_id, player_buff_ids, self.songs) >= self.brd_job:get_max_num_songs() then
            return false
        end
        if self.brd_job:is_nitro_ready() --[[]and not self.song_tracker:has_any_song(song_target_id, song_ids, player_buff_ids)]] then
            self:nitro()
            return true
        end
        -- Get next real song
        for song in self.songs:it() do
            if not self.song_tracker:has_song(song_target_id, song:get_spell().id, player_buff_ids) then
                self:sing_song(song)
                return true
            end
        end
    end
    return false
end

function Singer:sing_next_piannisimo_song()
    for party_member in self:get_party():get_party_members(false, 21):it() do
        if party_member:is_alive() then
            if party_member:is_trust() then
                self.song_tracker:prune_expired_songs(party_member:get_id())
            end
            for song in self.pianissimo_songs:it() do
                if not self.song_tracker:has_song(party_member:get_mob().id, song:get_spell().id, party_member:get_buff_ids())
                        and song:get_job_names():contains(party_member:get_main_job_short()) then
                    self:sing_song(song, party_member:get_mob().index)
                    return true
                end
            end
        end
    end
    return false
end

function Singer:sing_song(song, target_index)
    if spell_util.can_cast_spell(song:get_spell().id) then
        local actions = L{}

        self.last_sing_time = os.time()

        for job_ability_name in song:get_job_abilities():it() do
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
    end
end

function Singer:resing_song(song_id)
    if self.debug then
        print('resinging '..res.spells:with('id', song_id).name)
    end
    for song in self.songs:it() do
        if song:get_spell().id == song_id then
            self:sing_song(song)
            return
        end
    end
end

function Singer:nitro()
    local actions = L{
        JobAbilityAction.new(0, 0, 0, 'Nightingale'),
        WaitAction.new(0, 0, 0, 1.5),
        JobAbilityAction.new(0, 0, 0, 'Troubadour'),
        WaitAction.new(0, 0, 0, 1)
    }

    local nitro_action = SequenceAction.new(actions, 'nitro')
    nitro_action.priority = ActionPriority.highest

    self.action_queue:push_action(nitro_action, true)
end

function Singer:set_dummy_songs(dummy_songs)
    self.dummy_songs = (dummy_songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
end

function Singer:set_songs(songs)
    self.songs = (songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id)  end)
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