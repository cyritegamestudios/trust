local res = require('resources')

local Singer = setmetatable({}, {__index = Role })
Singer.__index = Singer

function Singer.new(action_queue, job_ability_names, dummy_songs, songs, brd_job, state_var, sing_action_priority)
    local self = setmetatable(Role.new(action_queue), Singer)

    self.job_ability_names = (job_ability_names or L{}):filter(function(job_ability_name) return job_util.knows_job_ability(job_util.job_ability_id(job_ability_name)) == true  end)
    self.dummy_songs = (dummy_songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
    self.songs = (songs or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id)  end)
    self.num_songs = #self.songs
    self.state_var = state_var or state.AutoSongMode
    self.sing_action_priority = sing_action_priority or ActionPriority.default
    self.last_sing_time = os.time()
    self.brd_job = brd_job

    return self
end

function Singer:destroy()
    Role.destroy(self)
end

function Singer:on_add()
    Role.on_add(self)
end

function Singer:target_change(target_index)
    Role.target_change(self, target_index)
end

function Singer:tic(_, _)
    if self.state_var.value == 'Off'
            or (os.time() - self.last_sing_time) < 6 then
        return
    end
    self:check_songs()
end

function Singer:check_songs()
    if self:get_player():is_moving() then
        return
    end

    local song = self:get_next_song()
    if song then
        self:sing_song(song)
    end
end

function Singer:get_next_song()
    local player_buff_ids = windower.ffxi.get_player().buffs

    local buffs_for_songs = self.songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end)
    local buffs_for_dummy_songs = self.dummy_songs:map(function(spell) return buff_util.buff_for_spell(spell:get_spell().id).id  end)
    local all_songs = buffs_for_songs:copy():extend(buffs_for_dummy_songs:copy())

    if not self.brd_job:has_all_songs(buffs_for_dummy_songs, L(player_buff_ids)) and (not self.brd_job:has_any_song(buffs_for_songs) or self.brd_job:get_num_songs(all_songs) < self.num_songs) then
        -- Get next dummy song
        for song in self.dummy_songs:it() do
            if not self.brd_job:has_song(song, L(player_buff_ids)) then
                self:sing_song(song, false)
                return
            end
        end
    elseif self.brd_job:get_num_songs(all_songs) == self.num_songs then
        if self.brd_job:is_nitro_ready() and not self.brd_job:has_any_song(buffs_for_songs, L(player_buff_ids)) then
            self:nitro()
            return
        end
        -- Get next real song
        for song in self.songs:it() do
            if not self.brd_job:has_song(song, L(player_buff_ids)) then
                self:sing_song(song)
                return
            end
        end
    end
end

function Singer:sing_song(song)
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

        actions:append(SpellAction.new(0, 0, 0, song:get_spell().id, nil, self:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))

        local sing_action = SequenceAction.new(actions, 'singer_'..song:get_spell().en)
        sing_action.priority = ActionPriority.highest

        self.action_queue:push_action(sing_action, true)
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

function Singer:allows_duplicates()
    return false
end

function Singer:get_type()
    return "singer"
end

return Singer