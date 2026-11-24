---------------------------
-- The Singer role: keeps the Bard's songs up.
--
-- Rewritten from scratch (2026-11-22). Same public interface and framework
-- integration as the original (a Gambiter role; the song tracker, the
-- on_songs_begin/on_songs_end events and the singer_gambits global are all
-- used elsewhere in Trust), with the internals rebuilt around one clear
-- priority order and one job-ability cooldown tracker.
-- Confirmed working in game (2026-11-22).
--
-- How singing works, in priority order (the Gambiter fires the first gambit
-- whose conditions all pass, one action at a time):
--
--   1. Nitro gambits  - the burst boosters (Soul Voice, Clarion Call,
--      Nightingale, Troubadour), used as a sequence at the start of a burst
--      or a refresh. Clarion Call also raises the song cap by 1, which is
--      how a Daurdabla Bard (cap 4) holds 5 songs.
--   2. Dummy gambits  - during the burst only, sing the dummy songs to hold
--      slots so the last real songs overwrite them and keep long durations,
--      while the early real songs keep their potency instruments (GearSwap
--      equips Daurdabla for the dummies; the singer only decides what to
--      sing and when, never the gear).
--   3. Song gambits   - one fill gambit (sing a missing song) and one
--      re-sing gambit (refresh a song before it expires) per real song.
--   4. Pianissimo     - single-target songs for party members.
--
-- Job-ability cooldowns: the client's recast table reads 0 (ready) until
-- the server's recast data arrives after a fresh start, and it can lag an
-- ability that was just used, so a recast-table gate alone lets attempts
-- through while an ability is still on cooldown ("Unable to use job
-- ability"). The Nitro gambits are re-evaluated every 1-3s during the
-- burst, so a stale read re-fires them mid-burst. To stay correct, the
-- singer records the last time each tracked ability was actually used
-- (seen via its buff) and gates on that record as well as the table. The
-- record is persisted to data/nitro_state.txt so it survives reloads.
-- Marcato (Honor March's ability, fired by the song itself) is tracked the
-- same way; its gate lives in job_util.can_use_job_ability, which the
-- song's ability filter also calls.
--
-- @class module
-- @name Singer

local ConditionalCondition = require('cylibs/conditions/conditional')
local CooldownCondition = require('cylibs/conditions/cooldown')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasMaxNumAlterEgosCondition = require('cylibs/conditions/has_max_num_alter_egos')
local HasMaxNumSongsCondition = require('cylibs/conditions/has_max_num_songs')
local JobAbilityRecastReadyCondition = require('cylibs/conditions/job_ability_recast_ready')
local MaxNumSongsCondition = require('cylibs/conditions/max_num_songs')
local NumExpiringSongsCondition = require('cylibs/conditions/num_expiring_songs')
local NumSongsCondition = require('cylibs/conditions/num_songs')
local Script = require('cylibs/battle/script')
local Sequence = require('cylibs/battle/sequence')
local SongDurationCondition = require('cylibs/conditions/song_duration')
local Wait = require('cylibs/battle/wait')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Singer = setmetatable({}, {__index = Gambiter })
Singer.__index = Singer
Singer.__class = "Singer"

local SongTracker = require('cylibs/battle/song_tracker')

-------
-- Job-ability cooldown tracker.
--
-- One entry per tracked ability: its name (as used by JobAbility.new and
-- the recast check), the key its last-use timestamp is stored under, its
-- recast in seconds, and the Bard method that reports whether its buff is
-- up. A use is only recorded when the buff is seen, so a failed attempt
-- (no buff) never wrongly blocks the ability.

local TRACKED_JAS = L{
    { name = 'Soul Voice',   key = 'soul_voice',   recast = 600, is_active = 'is_soul_voice_active' },
    { name = 'Clarion Call', key = 'clarion_call', recast = 600, is_active = 'is_clarion_call_active' },
    { name = 'Nightingale',  key = 'nightingale',  recast = 600, is_active = 'is_nightingale_active' },
    { name = 'Troubadour',   key = 'troubadour',   recast = 600, is_active = 'is_troubadour_active' },
    { name = 'Marcato',      key = 'marcato',      recast = 60,  is_active = 'is_marcato_active' },
}

local function tracked_ja(name)
    for ja in TRACKED_JAS:it() do
        if ja.name == name then
            return ja
        end
    end
    return nil
end

local function ja_state_path()
    return windower.addon_path .. 'data/nitro_state.txt'
end

-- Reads the persisted last-use timestamps (one "<key> <timestamp>" line per
-- ability). Falls back to the earlier single-ability file for Soul Voice.
local function read_ja_state()
    local states = {}
    pcall(function()
        local f = io.open(ja_state_path(), 'r')
        if not f then return end
        for line in f:lines() do
            local key, ts = line:match('^(%S+)%s+(%d+)$')
            if key and ts then states[key] = tonumber(ts) end
        end
        f:close()
    end)
    if not states['soul_voice'] then
        local ok, ts = pcall(function()
            local f = io.open(windower.addon_path .. 'data/soul_voice_state.txt', 'r')
            if not f then return nil end
            local line = f:read('*l')
            f:close()
            return tonumber(line)
        end)
        if ok and ts then states['soul_voice'] = ts end
    end
    return states
end

local function save_ja_state(states)
    pcall(function()
        local f = io.open(ja_state_path(), 'w')
        if not f then return end
        for ja in TRACKED_JAS:it() do
            local ts = states[ja.key]
            if ts then f:write(ja.key .. ' ' .. tostring(ts) .. '\n') end
        end
        f:close()
    end)
end

-------
-- Gambit builders. set_song_settings assembles the gambit list from these,
-- in the priority order described at the top of the file.

-- The conditions every Nitro gambit needs for its abilities: for each
-- ability in the sequence, BOTH the recast-table gate and the buff-based
-- cooldown record must say it is ready. (The sequence re-checks the recast
-- table when it runs; gating here too means the Gambiter skips straight to
-- a combo that can actually fire instead of pushing a doomed sequence.)
local function nitro_ja_conditions(ja_names)
    local conditions = L{}
    for name in ja_names:it() do
        local ja = tracked_ja(name)
        conditions:append(GambitCondition.new(JobAbilityRecastReadyCondition.new(name), GambitTarget.TargetType.Self))
        conditions:append(GambitCondition.new(CooldownCondition.new(ja.key, ja.recast), GambitTarget.TargetType.Self))
    end
    return conditions
end

-- A Nitro sequence: first mark every song expiring soon, so the songs are
-- re-sung with the Nitro boost, then wait 2s, then the abilities with a 1s
-- wait between each. The 2s head wait is for a fresh start: singing begins
-- the moment the fifth Trust lands, and the first ability (Soul Voice) can
-- go out while still in the tail of that summon cast, which the server
-- rejects with "Unable to use job ability" even though its timer is ready.
-- The wait costs 2s on every Nitro run (fresh burst and refresh alike);
-- mid-session there is no cast to race, so it is just a harmless pause.
-- The script reads the song tracker when it runs, not when the
-- sequence is built, so it is safe to build before the tracker exists.
local function nitro_sequence(singer, ja_names)
    local actions = L{
        Script.new(function()
            singer.song_tracker:set_all_expiring_soon()
        end),
        Wait.new(2),
    }
    for i, name in ipairs(ja_names) do
        if i > 1 then
            actions:append(Wait.new(1))
        end
        actions:append(JobAbility.new(name))
    end
    return Sequence.new(actions)
end

-- The Nitro combos, best first. 'slots' combos (the ones with Clarion
-- Call) fire while there is still a song slot to gain; 'burst' combos fire
-- at the start of a burst or a refresh (no songs up, or one expiring).
-- AutoNitroMode must be Auto for all of them; the other modes are per
-- combo. If a combo's abilities are on cooldown, its conditions fail and
-- the Gambiter falls through to the next combo.
local NITRO_COMBOS = {
    { modes = L{ 'AutoClarionCallMode', 'AutoSoulVoiceMode' },
      jas = L{ 'Soul Voice', 'Clarion Call', 'Nightingale', 'Troubadour' }, trigger = 'slots' },
    { modes = L{ 'AutoClarionCallMode' },
      jas = L{ 'Clarion Call', 'Nightingale', 'Troubadour' }, trigger = 'slots' },
    { modes = L{ 'AutoSoulVoiceMode' },
      jas = L{ 'Soul Voice', 'Nightingale', 'Troubadour' }, trigger = 'burst' },
    { modes = L{ },
      jas = L{ 'Nightingale', 'Troubadour' }, trigger = 'burst' },
}

local function burst_trigger_condition()
    return GambitCondition.new(ConditionalCondition.new(L{
        NumSongsCondition.new(0, Condition.Operator.Equals),
        NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
    }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self)
end

local function build_nitro_gambits(singer)
    local gambits = L{}
    for _, combo in ipairs(NITRO_COMBOS) do
        local conditions = L{
            GambitCondition.new(ModeCondition.new('AutoNitroMode', 'Auto'), GambitTarget.TargetType.Self),
        }
        for mode in combo.modes:it() do
            conditions:append(GambitCondition.new(ModeCondition.new(mode, 'Auto'), GambitTarget.TargetType.Self))
        end
        conditions = conditions + nitro_ja_conditions(combo.jas)
        if combo.trigger == 'slots' then
            conditions:append(GambitCondition.new(NumSongsCondition.new(singer.job.max_num_songs + 1, Condition.Operator.LessThan, true), GambitTarget.TargetType.Self))
        else
            conditions:append(burst_trigger_condition())
        end
        gambits:append(Gambit.new(GambitTarget.TargetType.Self, conditions, nitro_sequence(singer, combo.jas), GambitTarget.TargetType.Self))
    end
    -- Re-sing trigger: every ~100s, if songs are up or expiring, mark them
    -- all expiring soon so the re-sing gambits refresh them.
    gambits:append(Gambit.new(GambitTarget.TargetType.Self, L{
        GambitCondition.new(CooldownCondition.new('resing_songs', 100), GambitTarget.TargetType.Self),
        burst_trigger_condition(),
    }, Sequence.new(L{
        Script.new(function()
            singer.song_tracker:set_all_expiring_soon()
        end),
    }), GambitTarget.TargetType.Self))
    return gambits
end

-- Dummy songs hold slots during the burst so the last real songs each have
-- a dummy to overwrite. They are burst-only:
--   * a dummy never goes off while a real song is expiring (that is a
--     refresh, and a dummy would take a slot and a cast for nothing, then
--     knock out a real song when it lands);
--   * a dummy never goes off once only one real song is missing (the burst
--     is done building; refilling a single freed slot with a dummy knocks
--     out a real song and starts a recast loop);
--   * both dummies are maintained (one per dummy gambit, each checking the
--     dummy itself is not already up), so both overwrites are ready.
local function build_dummy_gambits(singer, dummy_song_threshold, real_song_names)
    local dummy_names = singer.dummy_songs:map(function(s) return s:get_name() end)
    local real_songs_to_close_gate = math.max(real_song_names:length() - 1, 1)
    return singer.dummy_songs:map(function(song)
        return Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(dummy_names, 2) }), GambitTarget.TargetType.Self),
            GambitCondition.new(NumSongsCondition.new(dummy_song_threshold, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
            GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Self),
            GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(real_song_names, real_songs_to_close_gate) }), GambitTarget.TargetType.Self),
            GambitCondition.new(NotCondition.new(L{ NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo) }), GambitTarget.TargetType.Self),
        }, song, Condition.TargetType.Self)
    end)
end

-- One fill gambit and one re-sing gambit per real song, in song order.
--
-- Fill fires when the song is missing, the song cap allows its slot, and
-- any of these holds: a dummy is up to overwrite, the burst is still below
-- the dummy threshold, a song is expiring (a refresh is under way), or
-- there is simply room for another song. The room clause is what refills
-- the 5th song after Clarion Call restores the cap: at 4 songs with cap 5
-- there is no dummy up and nothing expiring, so without it the missing
-- song would never come back on its own. At cap (e.g. 4 of 4) the clause
-- is false, so a missing song is left alone rather than overwriting a
-- real one.
--
-- Re-sing fires when the song is up but its remaining duration drops below
-- the re-sing duration.
local function build_song_gambits(singer, dummy_song_threshold)
    local dummy_names = singer.dummy_songs:map(function(s) return s:get_name() end)
    local gambits = L{}
    for songNum, song in ipairs(singer.songs) do
        song:set_requires_all_job_abilities(false)
        gambits = gambits + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(MaxNumSongsCondition.new(songNum, Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Self),
                GambitCondition.new(ConditionalCondition.new(L{
                    HasSongsCondition.new(dummy_names, 1),
                    NumSongsCondition.new(dummy_song_threshold, Condition.Operator.LessThan),
                    NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
                    HasMaxNumSongsCondition.new(Condition.Operator.LessThan),
                }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(HasSongsCondition.new(L{ song:get_name() }), GambitTarget.TargetType.Self),
                GambitCondition.new(SongDurationCondition.new(L{ song:get_name() }, singer.expiring_duration, Condition.Operator.LessThan), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self),
        }
    end
    return gambits
end

-- Pianissimo gambits. Two groups:
--   * With ResingMissingSongs on, Pianissimo versions of the dummy and
--     real-song fill gambits, aimed at party members (allies), so a member
--     who missed the songs can be caught up one song at a time.
--   * The dedicated Pianissimo songs (e.g. Mage's Ballad III), sung on
--     self or an ally whose job matches the song's job list.
local function build_pianissimo_gambits(singer, dummy_gambits, dummy_song_threshold)
    local gambits = L{}
    if singer.resing_missing_songs then
        local dummy_names = singer.dummy_songs:map(function(s) return s:get_name() end)
        gambits = dummy_gambits:map(function(gambit)
            local song = gambit:getAbility():copy()
            song:set_job_abilities(L{ "Pianissimo" })
            song:set_requires_all_job_abilities(true)

            return Gambit.new(GambitTarget.TargetType.Ally, gambit:getConditions():map(function(condition)
                return GambitCondition.new(condition:getCondition(), GambitTarget.TargetType.Ally)
            end), song, GambitTarget.TargetType.Ally)
        end) + singer.songs:map(function(song)
            local song = song:copy()
            song:set_job_abilities(L{ "Pianissimo" })
            song:set_requires_all_job_abilities(true)

            return Gambit.new(GambitTarget.TargetType.Ally, L{
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Ally),
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Ally),
                GambitCondition.new(ConditionalCondition.new(L{
                    HasSongsCondition.new(dummy_names, 1),
                    NumSongsCondition.new(dummy_song_threshold, Condition.Operator.LessThan),
                }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Ally),
            }, song, Condition.TargetType.Ally)
        end)
    end

    for song in singer.pianissimo_songs:it() do
        song:set_job_abilities(L{ "Pianissimo" })
        song:set_requires_all_job_abilities(true)

        for targetType in L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }:it() do
            gambits = gambits + L{
                Gambit.new(targetType, L{
                    GambitCondition.new(ModeCondition.new('AutoPianissimoMode', 'Auto'), GambitTarget.TargetType.Self),
                    GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), targetType),
                    GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.GreaterThanOrEqualTo), GambitTarget.TargetType.Self),
                    GambitCondition.new(JobCondition.new(song:get_job_names()), targetType),
                }, song, targetType),
            }
        end
    end
    return gambits
end

-------
-- The Singer role itself.

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
    self.ja_last_use = {}
    self.last_weaponskill_time = 0

    self:set_song_settings(song_settings)

    return self
end

function Singer:destroy()
    Gambiter.destroy(self)

    -- Clear the global song-set gambits so the song-set editor cannot
    -- read the old singer's gambits after this singer is destroyed.
    singer_gambits = nil

    self.dispose_bag:destroy()
end

function Singer:check_gambits(gambits, param, ignore_delay)
    -- Hold songs while TP is banked for a weaponskill: the
    -- weaponskill gets used first, then singing resumes on the
    -- next tic once TP drops below 500. Applies between fights
    -- (so the next mob is engaged and the weaponskill spent
    -- before a burst starts) and mid-fight alike. Same 500 TP
    -- trip point as the debuffer and puller holds.
    local ffxi_player = windower.ffxi.get_player()
    if ffxi_player and ffxi_player.tp and ffxi_player.tp >= 500 then
        return
    end
    -- Also hold for 2 seconds after a weaponskill lands: the TP
    -- hold above releases the moment the weaponskill spends the
    -- TP, and a song cast sent inside the weaponskill's action
    -- lock fails with "Unable to cast at this time" -- the same
    -- failure the debuffer's post-weaponskill hold covers. Songs
    -- resume on the next tic once the lock has passed, so singing
    -- levels out with the weaponskill instead of colliding with it.
    if self.last_weaponskill_time and os.clock() - self.last_weaponskill_time < 2 then
        return
    end
    return Gambiter.check_gambits(self, gambits, param, ignore_delay)
end

-------
-- Returns whether a burst is still pending: any configured song is
-- missing on the player or close to expiring. The singer is only
-- "active" while a cast is running, so between the songs of a burst
-- get_is_singing() reads false even though the burst is unfinished;
-- the puller uses this to avoid claiming a mob in those gaps, so a
-- burst always finishes before a claim. False when the auto singer
-- is off, when there is no tracker yet, or when every song is up
-- with time to spare.
-- @treturn boolean True if the singer still has songs to sing
function Singer:has_songs_pending()
    if not self.song_tracker then
        return false
    end
    if state.AutoSongMode.value ~= 'Auto' then
        return false
    end
    local player = self:get_player()
    if not player then
        return false
    end
    local player_id = player:get_id()
    for song in self.songs:it() do
        if not self.song_tracker:has_song(player_id, song:get_spell().id) then
            return true
        end
    end
    return self.song_tracker:is_expiring_soon(player_id, self.songs)
end

-------
-- Forwards the per-second tic to the song tracker so its expiration sweep
-- actually runs (Trust:tic calls role:tic when it exists), and records each
-- tracked job ability's use the moment its buff appears. Only the buff
-- proves the ability worked: a failed attempt shows no buff, so nothing is
-- recorded and the ability is not wrongly blocked.
function Singer:tic(_, _)
    if self.song_tracker then
        self.song_tracker:tic()
    end
    local player = windower.ffxi.get_player()
    if player and self.job then
        local now = os.time()
        local changed = false
        for ja in TRACKED_JAS:it() do
            local is_active = self.job[ja.is_active]
            if type(is_active) == 'function' and is_active(self.job) then
                local last_use = CooldownCondition.get_timestamp(ja.key)
                if not last_use or now - last_use >= 60 then
                    CooldownCondition.set_timestamp(ja.key, now)
                    self.ja_last_use[ja.key] = now
                    changed = true
                end
            end
        end
        if changed then
            save_ja_state(self.ja_last_use)
        end
    end
end

function Singer:on_add()
    Gambiter.on_add(self)

    -- Remember when the player's weaponskill lands (action packet
    -- category 3) so check_gambits can hold songs for 2 seconds
    -- after it, out of the weaponskill's action lock.
    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        local player = windower.ffxi.get_player()
        if player and act.actor_id == player.id and act.category == 3 then
            self.last_weaponskill_time = os.clock()
        end
    end), WindowerEvents.Action)

    CooldownCondition.set_timestamp('resing_songs', os.time())

    -- Seed the tracked abilities' cooldowns from their last recorded uses,
    -- so a fresh start (or a //lua reload trust) inside a recast skips them
    -- instead of attempting them. No record for an ability means this
    -- singer has never used it, so allow it (timestamp 0).
    self.ja_last_use = read_ja_state()
    for ja in TRACKED_JAS:it() do
        CooldownCondition.set_timestamp(ja.key, self.ja_last_use[ja.key] or 0)
    end

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

    -- Dummies start once this many songs are up. While Clarion Call is up
    -- the threshold rises by 1: Clarion Call fires at the start of the
    -- burst, so in a normal burst the third real song lands before the
    -- dummies (Honor March, Victory March, Minuet IV, then the dummies,
    -- then Minuet V and Blade Madrigal overwrite them).
    local dummy_song_threshold = song_settings.DummySongThreshold
    if self.job:is_clarion_call_active() then
        dummy_song_threshold = dummy_song_threshold + 1
    end
    local real_song_names = self.songs:map(function(song) return song:get_name() end)

    local gambit_settings = {
        Gambits = L{},
        Nitro = build_nitro_gambits(self),
        DummySongs = build_dummy_gambits(self, dummy_song_threshold, real_song_names),
        Songs = build_song_gambits(self, dummy_song_threshold),
        PianissimoSongs = L{},
    }
    gambit_settings.PianissimoSongs = build_pianissimo_gambits(self, gambit_settings.DummySongs, dummy_song_threshold)

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
        -- Only sing once the party is full: the Truster summons all alter
        -- egos first, then songs go up, then the puller pulls. Without this
        -- the singer starts after the first trusts are out and its constant
        -- re-singing keeps the Truster from ever finishing the party.
        GambitCondition.new(HasMaxNumAlterEgosCondition.new(), GambitTarget.TargetType.Self),
    }
    if gambit:getAbilityTarget() ~= GambitTarget.TargetType.Self then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end
    return conditions + self.job:get_conditions_for_ability(gambit:getAbility()):map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Singer:get_dummy_songs()
    return self.dummy_songs
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
