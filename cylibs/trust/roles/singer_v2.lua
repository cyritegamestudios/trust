local BlockAction = require('cylibs/actions/block')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasMaxNumSongsCondition = require('cylibs/conditions/has_max_num_songs')
local NumSongsCondition = require('cylibs/conditions/num_songs')
local logger = require('cylibs/logger/logger')
local res = require('resources')
local SongDurationCondition = require('cylibs/conditions/song_duration')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Singer = setmetatable({}, {__index = Gambiter })
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

function Singer.new(action_queue, song_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, state.AutoSongMode), Singer)

    self.job = job
    self.expiring_duration = 260
    self.last_expire_time = os.time() - 60
    self.songs_begin = Event.newEvent()
    self.songs_end = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    self:set_song_settings(song_settings)

    return self
end

function Singer:on_add()
    Gambiter.on_add(self)

    self.song_tracker = SongTracker.new(self:get_player(), self:get_party(), self.dummy_songs, self.songs, L{}, self.job, self.expiring_duration)
    self.song_tracker:monitor()

    --[[self.song_tracker:on_song_duration_warning():addAction(function(_)
        if os.time() - self.last_expire_time < 60 then
            print('nope', os.time() - self.last_expire_time)
            return
        end
        print('expiring!')
        self.last_expire_time = os.time()
        self.song_tracker:set_expiring_soon(self:get_party():get_player():get_id(), self.expiring_duration, true)
    end)]]

    self.dispose_bag:addAny(L{ self.song_tracker })
end

function Singer:tic(new_time, old_time)
    self.song_tracker:tic(new_time, old_time)

    Gambiter.tic(self, new_time, old_time)

    --print('checking', Condition.check_conditions(L{ SongDurationCondition.new(self.songs:map(function(song) return song:get_name() end) + self.pianissimo_songs:map(function(song) return song:get_name() end), 260, Condition.Operator.LessThanOrEqualTo, 1, Condition.Operator.GreaterThanOrEqualTo) }, windower.ffxi.get_player().index))
end

function Singer:set_song_settings(song_settings)
    self.dummy_songs = song_settings.DummySongs
    self.songs = song_settings.SongSets[state.SongSet.value].Songs
    self.pianissimo_songs = song_settings.SongSets[state.SongSet.value].PianissimoSongs

    local expire_duration = self.expiring_duration

    --local gambit_settings = {
    --    Gambits = L{
    --        Gambit.new(GambitTarget.TargetType.Self, L{
    --            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song_settings.DummySongs[1]:get_name() }, 1) }), GambitTarget.TargetType.Self),
    --            GambitCondition.new(NumSongsCondition.new(2, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
    --            GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Self),
    --        }, song_settings.DummySongs[1], Condition.TargetType.Self),
    --        --Gambit.new(GambitTarget.TargetType.Self, L{
    --        --    GambitCondition.new(NotCondition.new(L{ SpellRecastReadyCondition.new(song_settings.DummySongs[1]:get_spell().id) }), GambitTarget.TargetType.Self),
    --        --    GambitCondition.new(NumSongsCondition.new(2, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
    --        --    GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Self),
    --        --}, Command.new(''), GambitTarget.TargetType.Self)
    --        --Gambit.new(GambitTarget.TargetType.Self, L{
    --        --    GambitCondition.new(SongDurationCondition.new(self.songs:map(function(song) return song:get_name() end) + self.pianissimo_songs:map(function(song) return song:get_name() end), expire_duration, Condition.Operator.LessThanOrEqualTo, 1, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
    --        --}, Command.new('// trust brd clear'), GambitTarget.TargetType.Self)
    --    }
    --}

    -- Blade Madrigal failing on resing because it gets overridden with mage's ballad III
    -- I think this will break if a job has > 2 pianissimo songs because it would get into a song loop
    -- What if I set it so when any of the main songs is expiring on the bard, it sets song state to having all main songs (up to max num songs) that are expiring so it triggers a resing of main songs

    -- How about self pianissimo only applies if bard has all real song buffs--but then how will madrigal get re-applied? How about if not has madrigal and any pianissimo songs are expiring?

    --local songs = L{ self.songs[1]:copy() } + self.songs

    local gambit_settings = {
        Gambits = L{
        }
    }

    gambit_settings.DummySongs = L{
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song_settings.DummySongs[1]:get_name() }, 1) }), GambitTarget.TargetType.Self),
            GambitCondition.new(NumSongsCondition.new(2, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
            GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Self),
        }, song_settings.DummySongs[1], Condition.TargetType.Self),
    }

    gambit_settings.Songs = L{}

    for song in self.songs:it() do
        song:set_job_abilities(L{})

        gambit_settings.Songs = gambit_settings.Songs + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
                GambitCondition.new(ConditionalCondition.new(L{ HasSongsCondition.new(L{ self.dummy_songs[1]:get_name() }), NumSongsCondition.new(2, Condition.Operator.LessThan), SongDurationCondition.new(self.pianissimo_songs:map(function(song) return song:get_name() end), self.expiring_duration, Condition.Operator.LessThanOrEqualTo, 1, Condition.Operator.GreaterThanOrEqualTo) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), GambitTarget.TargetType.Self),
                GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, self.expiring_duration, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self)
        }
    end

    gambit_settings.PianissimoSongs = L{}

    for song in self.pianissimo_songs:it() do
        song:set_job_abilities(L{ "Pianissimo" })
        song:set_requires_all_job_abilities(true)

        local targetType = GambitTarget.TargetType.Self

        gambit_settings.PianissimoSongs = gambit_settings.PianissimoSongs + L{
            Gambit.new(targetType, L{
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), targetType),
                --GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.Equals), GambitTarget.TargetType.Self),
                GambitCondition.new(HasSongsCondition.new(self.songs:map(function(song) return song:get_name() end)), GambitTarget.TargetType.Self), -- only allows for a single pianissimo song
                GambitCondition.new(JobCondition.new(song:get_job_names()), targetType),
            }, song, targetType),
            --Gambit.new(GambitTarget.TargetType.Self, L{
            --    GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), targetType),
            --    GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, self.expiring_duration, Condition.Operator.LessThan), targetType),
            --}, song, Condition.TargetType.Self)
        }
    end

    --for song_index = 1, songs:length() do
    --    local song = songs[song_index]
    --    if song_index == 1 then
    --        song:set_job_abilities(L{ --[['Nightingale', 'Troubadour', 'Marcato']] })
    --        song:set_requires_all_job_abilities(true)
    --    else
    --        song:set_job_abilities(L{})
    --    end
    --
    --    gambit_settings.Gambits = gambit_settings.Gambits + L{
    --        Gambit.new(GambitTarget.TargetType.Self, L{
    --            --GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.Equals), GambitTarget.TargetType.Self),
    --            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
    --            GambitCondition.new(SongDurationCondition.new(self.pianissimo_songs:map(function(song) return song:get_name() end), expire_duration, Condition.Operator.LessThanOrEqualTo, 1, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
    --        }, song, Condition.TargetType.Self),
    --        Gambit.new(GambitTarget.TargetType.Self, L{
    --            GambitCondition.new(SpellRecastReadyCondition.new(song_settings.DummySongs[1]:get_spell().id), GambitTarget.TargetType.Self),
    --            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
    --            GambitCondition.new(ConditionalCondition.new(L{ HasSongsCondition.new(L{ self.dummy_songs[1]:get_name() }), NumSongsCondition.new(2, Condition.Operator.LessThan) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
    --        }, song, Condition.TargetType.Self),
    --        Gambit.new(GambitTarget.TargetType.Self, L{
    --            GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), GambitTarget.TargetType.Self),
    --            GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, expire_duration, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
    --        }, song, Condition.TargetType.Self)
    --    }
    --end

    --[[for targetType in L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }:it() do
        for song in song_settings.SongSets[state.SongSet.value].PianissimoSongs:it() do
            gambit_settings.Gambits = gambit_settings.Gambits + L{
                Gambit.new(targetType, L{
                    GambitCondition.new(SpellRecastReadyCondition.new(song_settings.DummySongs[1]:get_spell().id), GambitTarget.TargetType.Self),
                    GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }, 1) }), targetType),
                    GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.Equals), GambitTarget.TargetType.Self),
                    GambitCondition.new(JobCondition.new(song:get_job_names()), targetType),
                }, song, targetType),
                Gambit.new(GambitTarget.TargetType.Self, L{
                    GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), targetType),
                    GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, expire_duration, Condition.Operator.LessThan), targetType),
                }, song, Condition.TargetType.Self)
            }
        end
    end]]

    --[[gambit_settings.Gambits = gambit_settings.Gambits + gambit_settings.Gambits:map(function(gambit)
        local ability = gambit:getAbility():copy()
        ability:set_job_abilities(L{ 'Pianissimo' })
        ability:set_requires_all_job_abilities(true)

        return Gambit.new(GambitTarget.TargetType.Ally, gambit:getConditions():map(function(condition)
            return GambitCondition.new(condition:getCondition(), GambitTarget.TargetType.Ally)
        end), ability, GambitTarget.TargetType.Ally)
    end)]]

    gambit_settings.Gambits = gambit_settings.DummySongs + gambit_settings.Songs + gambit_settings.PianissimoSongs

    self.gambit_settings = gambit_settings

    for gambit in gambit_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    self:set_gambit_settings(gambit_settings)

    singer_gambits = gambit_settings.Gambits
end

function Singer:get_default_conditions(gambit)
    local conditions = L{
        MinHitPointsPercentCondition.new(1),
    }
    if gambit:getAbilityTarget() ~= GambitTarget.TargetType.Self then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end
    return conditions + self.job:get_conditions_for_ability(gambit:getAbility()):map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Singer:get_all_gambits()
    if self.song_tracker:is_expiring_soon(self:get_party():get_player():get_id(), self.songs) then
        print('diong regular songs')
        return self.gambit_settings.DummySongs + self.gambit_settings.Songs
    end
    print('doing pianissimo')
    return Gambiter.get_all_gambits(self)
end

function Singer:set_is_singing(is_singing)
    if self.is_singing == is_singing then
        return
    end
    self.is_singing = is_singing
end

function Singer:get_is_singing()
    return self.is_singing
end

function Singer:allows_duplicates()
    return true
end

function Singer:allows_multiple_actions()
    return false
end

function Singer:get_type()
    return "singer"
end

function Singer:get_cooldown()
    return 5
end

function Singer:get_localized_name()
    return "Singing"
end

function Singer:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Singer