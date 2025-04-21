local BlockAction = require('cylibs/actions/block')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local NumSongsCondition = require('cylibs/conditions/num_songs')
local logger = require('cylibs/logger/logger')
local res = require('resources')

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

    local songs = L{

    }

    self.song_tracker = SongTracker.new(self:get_player(), self:get_party(), self.dummy_songs, self.songs, L{}, self.job)
    self.song_tracker:monitor()

    self.dispose_bag:addAny(L{ self.song_tracker })
end

function Singer:tic(new_time, old_time)
    Gambiter.tic(self, new_time, old_time)

    self.song_tracker:tic(new_time, old_time)
end

function Singer:set_song_settings(song_settings)
    -- 1. Sing Song 1 if not has song 1 and current num songs < 2
    -- 2. Sing Song 2 if not has song 2 and current num songs < 2
    -- 3. Sing Dummy Song if not has dummy song, current num songs >= 2 and current num songs < max num songs
    -- 4. Sing Song 3 if not has song 3, has song 1, song 2 and dummy song
    -- 5. Sing Song 4 if not has song 4, has song 1, song 2, song 3 and dummy song

    local song1 = Gambit.new(GambitTarget.TargetType.Self, L{
        NotCondition.new(L{ HasSongsCondition.new(L{ 'Honor March' }, 1) }),
        NumSongsCondition.new(2, Condition.Operator.LessThan),
    }, Spell.new('Honor March'), Condition.TargetType.Self)

    local song2 = Gambit.new(GambitTarget.TargetType.Self, L{
        NotCondition.new(L{ HasSongsCondition.new(L{ 'Blade Madrigal' }, 1) }),
        NumSongsCondition.new(2, Condition.Operator.LessThan),
    }, Spell.new('Blade Madrigal'), Condition.TargetType.Self)

    local dummySong = Gambit.new(GambitTarget.TargetType.Self, L{
        NotCondition.new(L{ HasSongsCondition.new(L{ "Scop's Operetta" }, 1) }),
        NumSongsCondition.new(2, Condition.Operator.GreaterThanOrEqualTo),
        NumSongsCondition.new(4, Condition.Operator.LessThan),
    }, Spell.new("Scop's Operetta"), Condition.TargetType.Self)

    local song3 = Gambit.new(GambitTarget.TargetType.Self, L{
        NotCondition.new(L{ HasSongsCondition.new(L{ 'Valor Minuet IV' }, 1) }),
        HasSongsCondition.new(L{ "Scop's Operetta" }, 1),
    }, Spell.new('Valor Minuet IV'), Condition.TargetType.Self)

    local song4 = Gambit.new(GambitTarget.TargetType.Self, L{
        NotCondition.new(L{ HasSongsCondition.new(L{ 'Valor Minuet V' }, 1) }),
        HasSongsCondition.new(L{ "Scop's Operetta" }, 1),
    }, Spell.new('Valor Minuet V'), Condition.TargetType.Self)

    self.songs = L{
        song1, song2, song3, song4
    }:map(function(gambit)
        return gambit:getAbility()
    end)

    self.dummy_songs = L{
        dummySong
    }:map(function(gambit)
        return gambit:getAbility()
    end)

    local gambit_settings = {
        Gambits = L{
            song1,
            song2,
            dummySong,
            song3,
            song4
        }
    }

    for gambit in gambit_settings.Gambits:it() do
        if gambit:getAbility().__type == Buff.__type then
            gambit:getAbility():reload()
        end
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