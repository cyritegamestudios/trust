local BlockAction = require('cylibs/actions/block')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasMaxNumSongsCondition = require('cylibs/conditions/has_max_num_songs')
local NumSongsCondition = require('cylibs/conditions/num_songs')
local logger = require('cylibs/logger/logger')
local res = require('resources')
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

    self.song_tracker = SongTracker.new(self:get_player(), self:get_party(), self.dummy_songs, self.songs, L{}, self.job, self.expiring_duration)
    self.song_tracker:monitor()

    self.dispose_bag:addAny(L{ self.song_tracker })
end

function Singer:set_song_settings(song_settings)
    self.dummy_songs = song_settings.DummySongs
    self.songs = song_settings.SongSets[state.SongSet.value].Songs
    self.pianissimo_songs = song_settings.SongSets[state.SongSet.value].PianissimoSongs
    self.expiring_duration = song_settings.ResingDuration or 60
    self.last_expire_time = os.time() - self.expiring_duration

    -- I think this will break if a job has > 2 pianissimo songs because it would get into a song loop
    -- What if I set it so when any of the main songs is expiring on the bard, it sets song state to having all main songs (up to max num songs) that are expiring so it triggers a resing of main songs

    -- How about self pianissimo only applies if bard has all real song buffs--but then how will madrigal get re-applied? How about if not has madrigal and any pianissimo songs are expiring?

    local gambit_settings = {
        Gambits = L{},
        DummySongs = L{},
        Songs = L{},
        PianissimoSongs = L{}
    }

    gambit_settings.DummySongs = L{
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song_settings.DummySongs[1]:get_name() }, 1) }), GambitTarget.TargetType.Self),
            GambitCondition.new(NumSongsCondition.new(2, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
            GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Self),
        }, song_settings.DummySongs[1], Condition.TargetType.Self),
    }

    -- There is some delay between songs because they aren't all under expire duration at the same time I think
    for song in self.songs:it() do
        --song:set_job_abilities(L{})
        song:set_requires_all_job_abilities(false)

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

    -- Pianissimo doesn't work when you don't have 5 songs because it requires you to have ALL main songs--need to cap at max num songs
    gambit_settings.PianissimoSongs = (gambit_settings.DummySongs + gambit_settings.Songs):map(function(gambit)
        local song = gambit:getAbility():copy()
        song:set_job_abilities(L{ "Pianissimo" })
        song:set_requires_all_job_abilities(true)

        return Gambit.new(GambitTarget.TargetType.Ally, gambit:getConditions():map(function(condition)
            return GambitCondition.new(condition:getCondition(), GambitTarget.TargetType.Ally)
        end), song, GambitTarget.TargetType.Ally)
    end)

    for song in self.pianissimo_songs:it() do
        song:set_job_abilities(L{ "Pianissimo" })
        song:set_requires_all_job_abilities(true)

        for targetType in L{ GambitTarget.TargetType.Ally, GambitTarget.TargetType.Self }:it() do
            gambit_settings.PianissimoSongs = gambit_settings.PianissimoSongs + L{
                Gambit.new(targetType, L{
                    GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), targetType),
                    GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.GreaterThanOrEqualTo, self.songs:map(function(song) return song:get_name() end)), GambitTarget.TargetType.Self),
                    GambitCondition.new(JobCondition.new(song:get_job_names()), targetType),
                }, song, targetType),
            }
        end
    end

    -- this works even for resing, but it does interrupt self nitro songs to re-pianissimo onto party members probably because Bard's songs
    -- aren't all under the expiring threshold...might want to set a higher threshold for when nitro is active so self songs take priority
    -- it will re-pianissimo ally songs in between nitro songs, which will cause unnecessary resings
    gambit_settings.Nitro = L{
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(ModeCondition.new('AutoClarionCallMode', 'Auto'), GambitTarget.TargetType.Self),
            GambitCondition.new(JobAbilityRecastReadyCondition.new("Nightingale"), GambitTarget.TargetType.Self),
            GambitCondition.new(JobAbilityRecastReadyCondition.new("Troubadour"), GambitTarget.TargetType.Self),
            GambitCondition.new(NumSongsCondition.new(song_settings.NumSongs + 1, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
        }, JobAbility.new("Clarion Call"), GambitTarget.TargetType.Self),
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(ModeCondition.new('AutoNitroMode', 'Auto'), GambitTarget.TargetType.Self),
            GambitCondition.new(ConditionalCondition.new(L{
                NumSongsCondition.new(0, Condition.Operator.Equals),
                SongDurationCondition.new((self.songs + self.pianissimo_songs):map(function(song) return song:get_name() end), self.expiring_duration, Condition.Operator.LessThanOrEqualTo, 1, Condition.Operator.GreaterThanOrEqualTo),
            }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
        }, Sequence.new(L{ JobAbility.new("Nightingale"), JobAbility.new("Troubadour") }), GambitTarget.TargetType.Self),
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
    if self.job:is_nitro_active() then
        return 1
    end
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