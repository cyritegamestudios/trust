local BlockAction = require('cylibs/actions/block')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
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
    self.songs_begin = Event.newEvent()
    self.songs_end = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    self:set_song_settings(song_settings)

    return self
end

function Singer:on_add()
    Gambiter.on_add(self)

    self.song_tracker = SongTracker.new(self:get_player(), self:get_party(), self.dummy_songs, self.songs, L{}, self.job)
    self.song_tracker:monitor()

    self.dispose_bag:addAny(L{ self.song_tracker })
end

function Singer:tic(new_time, old_time)
    Gambiter.tic(self, new_time, old_time)

    self.song_tracker:tic(new_time, old_time)
end

function Singer:set_song_settings(song_settings)
    --self.job:set_trust_settings(song_settings)

    self.dummy_songs = song_settings.DummySongs
    self.songs = song_settings.SongSets[state.SongSet.value].Songs
    self.pianissimo_songs = song_settings.SongSets[state.SongSet.value].PianissimoSongs

    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song_settings.DummySongs[1]:get_name() }, 1) }), GambitTarget.TargetType.Self),
                GambitCondition.new(NumSongsCondition.new(2, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
                GambitCondition.new(NumSongsCondition.new(song_settings.NumSongs, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
            }, song_settings.DummySongs[1], Condition.TargetType.Self)
        }
    }

    -- 1. Don't have the song
    -- 2. Dummy song recast is ready
    -- 3. Fewer than 2 songs or have dummy song
    -- 4.

    -- 1. Don't have the song
    -- 2. Fewer than 2 songs or have dummy song
    -- 3. Have all previous songs
    -- 4. Have
    -- 5.

    for song in song_settings.SongSets[state.SongSet.value].Songs:it() do
        song:set_requires_all_job_abilities(false)

        gambit_settings.Gambits = gambit_settings.Gambits + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                SpellRecastReadyCondition.new(song_settings.DummySongs[1]:get_spell().id),
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
                GambitCondition.new(ConditionalCondition.new(L{ HasSongsCondition.new(L{ self.dummy_songs[1]:get_name() }), NumSongsCondition.new(2, Condition.Operator.LessThan) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                SpellRecastReadyCondition.new(song_settings.DummySongs[1]:get_spell().id),
                GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), GambitTarget.TargetType.Self),
                GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, 240, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self)
        }
    end

    gambit_settings.Gambits = L{
        --Gambit.new(GambitTarget.TargetType.Self, L{
        --    GambitCondition.new(SongDurationCondition.new(L{ self.songs:map(function(song) return song:get_name() end) }, 120, Condition.LogicalOperator.LessThan))
        --}, Command.new("// trust brd resing", L{}, "Resinging all songs"), Condition.TargetType.Self),
    } + gambit_settings.Gambits + gambit_settings.Gambits:map(function(gambit)
        local ability = gambit:getAbility():copy()
        ability:set_job_abilities(L{ 'Pianissimo' })

        return Gambit.new(GambitTarget.TargetType.Ally, gambit:getConditions():map(function(condition)
            return GambitCondition.new(condition:getCondition(), GambitTarget.TargetType.Ally)
        end), ability, GambitTarget.TargetType.Ally)
    end)

    --[[for song in song_settings.SongSets[state.SongSet.value].PianissimoSongs:it() do
        local gambit = Gambit.new(GambitTarget.TargetType.Ally, L{
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }, 1) }), GambitCondition.TargetType.Ally),
            GambitCondition.new(NumSongsCondition.new(4, Condition.Operator.LessThan), GambitCondition.TargetType.Ally),
            GambitCondition.new(JobCondition.new(song:get_job_names()))
        }, song, Condition.TargetType.Ally)

        gambit_settings.Gambits:append(gambit)
    end]]

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