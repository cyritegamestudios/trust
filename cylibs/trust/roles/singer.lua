local ConditionalCondition = require('cylibs/conditions/conditional')
local CooldownCondition = require('cylibs/conditions/cooldown')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasMaxNumSongsCondition = require('cylibs/conditions/has_max_num_songs')
local MaxNumSongsCondition = require('cylibs/conditions/max_num_songs')
local NumExpiringSongsCondition = require('cylibs/conditions/num_expiring_songs')
local NumSongsCondition = require('cylibs/conditions/num_songs')
local Script = require('cylibs/battle/script')
local Sequence = require('cylibs/battle/sequence')
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
    self.songs_begin = Event.newEvent()
    self.songs_end = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    self:set_song_settings(song_settings)

    return self
end

function Singer:on_add()
    Gambiter.on_add(self)

    CooldownCondition.set_timestamp('resing_songs', os.time())

    self.song_tracker = SongTracker.new(self:get_player(), self:get_party(), self.dummy_songs, self.songs, self.pianissimo_songs, self.job, self.expiring_duration)
    self.song_tracker:monitor()

    self.dispose_bag:addAny(L{ self.song_tracker })

    self.dispose_bag:add(self:on_active_changed():addAction(function(_, is_singing)
        self:set_is_singing(is_singing)
        if not is_singing then
            self:check_gambits(nil, nil, true)
        end
    end), self:on_active_changed())
end

function Singer:set_song_settings(song_settings)
    self.dummy_songs = song_settings.DummySongs
    self.songs = song_settings.SongSets[state.SongSet.value].Songs
    self.pianissimo_songs = song_settings.SongSets[state.SongSet.value].PianissimoSongs
    self.expiring_duration = song_settings.ResingDuration or 75
    self.resing_missing_songs = song_settings.ResingMissingSongs
    self.last_expire_time = os.time() - self.expiring_duration

    if self.song_tracker then
        self.song_tracker.songs = self.songs
        self.song_tracker.dummy_songs = self.dummy_songs
        self.song_tracker.pianissimo_songs = self.pianissimo_songs
        self.song_tracker.expiring_duration = self.expiring_duration
    end

    local gambit_settings = {
        Gambits = L{},
        DummySongs = L{},
        Songs = L{},
        PianissimoSongs = L{}
    }

    local dummy_song_threshold = song_settings.DummySongThreshold
    if self.job:is_clarion_call_active() then
        dummy_song_threshold = dummy_song_threshold + 1
    end

    gambit_settings.DummySongs = song_settings.DummySongs:map(function(song)
        return Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(song_settings.DummySongs:map(function(s) return s:get_name() end), 1) }), GambitTarget.TargetType.Self),
            GambitCondition.new(NumSongsCondition.new(dummy_song_threshold, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
            GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Self),
        }, song, Condition.TargetType.Self)
    end)

    for songNum, song in ipairs(self.songs) do
        song:set_requires_all_job_abilities(false)

        gambit_settings.Songs = gambit_settings.Songs + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxNumSongsCondition.new(songNum, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
                GambitCondition.new(ConditionalCondition.new(L{
                    HasSongsCondition.new(song_settings.DummySongs:map(function(s) return s:get_name() end), 1),
                    NumSongsCondition.new(dummy_song_threshold, Condition.Operator.LessThan),
                    NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
                }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), GambitTarget.TargetType.Self),
                GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, self.expiring_duration, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self)
        }
    end

    if self.resing_missing_songs then
        gambit_settings.PianissimoSongs = gambit_settings.DummySongs:map(function(gambit)
            local song = gambit:getAbility():copy()
            song:set_job_abilities(L{ "Pianissimo" })
            song:set_requires_all_job_abilities(true)

            return Gambit.new(GambitTarget.TargetType.Ally, gambit:getConditions():map(function(condition)
                return GambitCondition.new(condition:getCondition(), GambitTarget.TargetType.Ally)
            end), song, GambitTarget.TargetType.Ally)
        end) + self.songs:map(function(song)
            local song = song:copy()
            song:set_job_abilities(L{ "Pianissimo" })
            song:set_requires_all_job_abilities(true)

            return Gambit.new(GambitTarget.TargetType.Ally, L{
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Ally),
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Ally),
                GambitCondition.new(ConditionalCondition.new(L{
                    HasSongsCondition.new(song_settings.DummySongs:map(function(s) return s:get_name() end), 1),
                    NumSongsCondition.new(dummy_song_threshold, Condition.Operator.LessThan),
                }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Ally),
            }, song, Condition.TargetType.Ally)
        end)
    end

    for song in self.pianissimo_songs:it() do
        song:set_job_abilities(L{ "Pianissimo" })
        song:set_requires_all_job_abilities(true)

        for targetType in L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }:it() do
            gambit_settings.PianissimoSongs = gambit_settings.PianissimoSongs + L{
                Gambit.new(targetType, L{
                    GambitCondition.new(ModeCondition.new('AutoPianissimoMode', 'Auto'), GambitTarget.TargetType.Self),
                    GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), targetType),
                    GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
                    GambitCondition.new(JobCondition.new(song:get_job_names()), targetType),
                }, song, targetType),
            }
        end
    end

    gambit_settings.Nitro = L{
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(ModeCondition.new('AutoClarionCallMode', 'Auto'), GambitTarget.TargetType.Self),
            GambitCondition.new(ModeCondition.new('AutoNitroMode', 'Auto'), GambitTarget.TargetType.Self),
            GambitCondition.new(NumSongsCondition.new(self.job.max_num_songs + 1, Condition.Operator.LessThan, true), GambitTarget.TargetType.Self),
        }, Sequence.new(L{
            Script.new(function()
                self.song_tracker:set_all_expiring_soon()
            end),
            JobAbility.new("Clarion Call"),
            JobAbility.new("Nightingale"),
            JobAbility.new("Troubadour")
        }), GambitTarget.TargetType.Self),
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(ModeCondition.new('AutoNitroMode', 'Auto'), GambitTarget.TargetType.Self),
            GambitCondition.new(ConditionalCondition.new(L{
                NumSongsCondition.new(0, Condition.Operator.Equals),
                NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
            }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
        }, Sequence.new(L{
            Script.new(function()
                self.song_tracker:set_all_expiring_soon()
            end),
            JobAbility.new("Nightingale"),
            JobAbility.new("Troubadour")
        }), GambitTarget.TargetType.Self),
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(CooldownCondition.new('resing_songs', 100), GambitTarget.TargetType.Self), -- is this necessary? probably
            GambitCondition.new(ConditionalCondition.new(L{
                NumSongsCondition.new(0, Condition.Operator.Equals),
                NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
            }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
        }, Sequence.new(L{
            Script.new(function()
                self.song_tracker:set_all_expiring_soon()
            end),
        }), GambitTarget.TargetType.Self),
    }

    gambit_settings.Gambits = gambit_settings.Nitro + gambit_settings.DummySongs + gambit_settings.Songs + gambit_settings.PianissimoSongs

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

function Singer:get_merged_songs(party_member, max_num_songs)
    local all_songs = L{} + self.songs

    local pianissimo_songs = self.pianissimo_songs:filter(function(song)
        return song:get_job_names():contains(party_member:get_main_job_short())
    end)

    if pianissimo_songs:length() > 0 then
        all_songs = pianissimo_songs + self.songs:slice(pianissimo_songs:length() + 1)
    end
    return all_songs
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

function Singer:allows_duplicates()
    return false
end

-- what if i allow multiple actions? will this make songs go into the queue before other actions
function Singer:allows_multiple_actions()
    return false
end

function Singer:get_type()
    return "singer"
end

function Singer:get_cooldown()
    if self.job:is_nitro_active() then
        return 1
    end
    return 3
end

function Singer:get_priority()
    return ActionPriority.highest
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