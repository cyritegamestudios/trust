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

local Condition = require('cylibs/conditions/condition')
local ConditionalCondition = require('cylibs/conditions/conditional')
local CooldownCondition = require('cylibs/conditions/cooldown')
local CommandAction = require('cylibs/actions/command')
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
-- recast in seconds, its job-ability id (the id the player's action
-- packets carry for it), and the Bard method that reports whether its
-- buff is up. A use is recorded from the action packet the moment the
-- ability lands; the per-second tic also records a use it finds no
-- fresh stamp for when the ability's buff is up, which covers uses
-- made while Trust was off. A failed attempt produces neither a
-- packet nor a buff, so it never wrongly blocks the ability.

local TRACKED_JAS = L{
    { name = 'Soul Voice',   key = 'soul_voice',   recast = 600, id = 25,  is_active = 'is_soul_voice_active' },
    { name = 'Clarion Call', key = 'clarion_call', recast = 600, id = 332, is_active = 'is_clarion_call_active' },
    { name = 'Nightingale',  key = 'nightingale',  recast = 600, id = 163, is_active = 'is_nightingale_active' },
    { name = 'Troubadour',   key = 'troubadour',   recast = 600, id = 164, is_active = 'is_troubadour_active' },
    { name = 'Marcato',      key = 'marcato',      recast = 600, id = 284, is_active = 'is_marcato_active' },
}

local function tracked_ja(name)
    for ja in TRACKED_JAS:it() do
        if ja.name == name then
            return ja
        end
    end
    return nil
end

-- The same entries by job-ability id, for recognising the player's own
-- ability uses in the action packet (category 6 carries the ability id
-- in param -- the same field cylibs/entity/player.lua reports through
-- on_job_ability_used).
local TRACKED_JA_BY_ID = {}
for ja in TRACKED_JAS:it() do
    TRACKED_JA_BY_ID[ja.id] = ja
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
-- Records a tracked ability's use at the given time: the shared
-- CooldownCondition timestamp every recast gate reads, the singer's
-- own copy, and the state file, so a //lua reload keeps the clock.
-- Called from the action-packet hook the moment a use lands, and
-- from the per-second tic as a fallback for uses made while Trust
-- was off (seen by their buff instead).
local function record_ja_use(singer, ja, now)
    CooldownCondition.set_timestamp(ja.key, now)
    singer.ja_last_use[ja.key] = now
    save_ja_state(singer.ja_last_use)
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
            -- Deliberate marking (no skip): if this sequence caught a
            -- burst already under way, the whole set is refreshed
            -- under the abilities, not just the songs not yet sung.
            singer.song_tracker:set_all_expiring_soon()
            -- Circuit breaker: stamp the attempt so no combo can
            -- fire again for 45 seconds, whatever happens to this
            -- sequence (see build_nitro_gambits).
            CooldownCondition.set_timestamp('nitro_attempt', os.time())
            -- Hold the burst's songs until the abilities have gone
            -- out (see Singer:check_gambits): the head wait, the
            -- waits between abilities and each ability's own action
            -- lock add up to roughly 3 seconds per ability, and the
            -- margin on top keeps a song from ever slipping in ahead
            -- of the last ability. The action hook releases the hold
            -- into a short grace the moment the last ability lands;
            -- this timer is the backstop for abilities that never
            -- land.
            singer.nitro_block_until = os.clock() + 3 * ja_names:length() + 3
            singer.nitro_block_jas = {}
            for name in ja_names:it() do
                local ja = tracked_ja(name)
                if ja then
                    singer.nitro_block_jas[ja.key] = true
                end
            end
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
--
-- The two combos without Soul Voice also come in a Marcato variant,
-- ranked just above the plain combo. Marcato never goes in a Soul Voice
-- combo (it does not stack with Soul Voice), and outside the sequence
-- it was effectively never used in a Nitro burst at all: the only other
-- path is Honor March's spell abilities, which read the song the set
-- has Marcato attached to -- on the wrong song, or reached after the
-- Nitro buffs fade, it just sits ready. As the sequence's last step it
-- lands after Nightingale and Troubadour are up and rides Honor March,
-- the first song of the burst. The variant's gambit requires Marcato
-- ready; on cooldown the Gambiter falls through to the plain combo, so
-- Marcato can never block Nitro -- the two share a 10-minute recast,
-- but a manual Marcato (or one spent through a song) desyncs them.
local NITRO_COMBOS = {
    { modes = L{ 'AutoClarionCallMode', 'AutoSoulVoiceMode' },
      jas = L{ 'Soul Voice', 'Clarion Call', 'Nightingale', 'Troubadour' }, trigger = 'slots' },
    { modes = L{ 'AutoClarionCallMode' },
      jas = L{ 'Clarion Call', 'Nightingale', 'Troubadour', 'Marcato' }, trigger = 'slots' },
    { modes = L{ 'AutoClarionCallMode' },
      jas = L{ 'Clarion Call', 'Nightingale', 'Troubadour' }, trigger = 'slots' },
    { modes = L{ 'AutoSoulVoiceMode' },
      jas = L{ 'Soul Voice', 'Nightingale', 'Troubadour' }, trigger = 'burst' },
    { modes = L{ },
      jas = L{ 'Nightingale', 'Troubadour', 'Marcato' }, trigger = 'burst' },
    { modes = L{ },
      jas = L{ 'Nightingale', 'Troubadour' }, trigger = 'burst' },
}

local function burst_trigger_condition()
    return GambitCondition.new(ConditionalCondition.new(L{
        NumSongsCondition.new(0, Condition.Operator.Equals),
        NumExpiringSongsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
    }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self)
end

-- How long after a song lands the burst that sang it still counts as
-- under way. A burst's songs land seconds apart (cast time plus the
-- singer's cooldown), so 45 seconds covers a burst's span with room
-- to spare, and a burst that stalls past it releases the hold below
-- on its own.
local BURST_ACTIVE_WINDOW = 45

-- Condition that holds the Nitro combos while a burst is under way
-- (see Singer:is_burst_underway). A combo whose abilities come off
-- cooldown mid-burst waits and leads the next burst instead of
-- firing into the middle of the current one, where it would boost
-- only the songs not yet sung and leave the set on two clocks.
local NoBurstUnderwayCondition = setmetatable({}, { __index = Condition })
NoBurstUnderwayCondition.__index = NoBurstUnderwayCondition
NoBurstUnderwayCondition.__type = "NoBurstUnderwayCondition"
NoBurstUnderwayCondition.__class = "NoBurstUnderwayCondition"

function NoBurstUnderwayCondition.new(singer)
    local self = setmetatable(Condition.new(), NoBurstUnderwayCondition)
    self.singer = singer
    return self
end

function NoBurstUnderwayCondition:is_satisfied(_)
    return not self.singer:is_burst_underway()
end

function NoBurstUnderwayCondition:get_config_items()
    return L{}
end

function NoBurstUnderwayCondition:tostring()
    return "No burst under way"
end

function NoBurstUnderwayCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

-- Condition that holds the dedicated Pianissimo songs (e.g. Mage's
-- Ballad III) while the singer's own set is due to be re-sung or a
-- burst is under way. A Ballad sung just ahead of a re-sing is wasted
-- motion: the re-sing's area casts trade it off the member again
-- (there is no sixth song slot), and one sung mid-burst lands
-- between the burst's songs. Held here, it goes out in the stable
-- window after the burst, when the set is up and not due.
local NoResingImminentCondition = setmetatable({}, { __index = Condition })
NoResingImminentCondition.__index = NoResingImminentCondition
NoResingImminentCondition.__type = "NoResingImminentCondition"
NoResingImminentCondition.__class = "NoResingImminentCondition"

function NoResingImminentCondition.new(singer)
    local self = setmetatable(Condition.new(), NoResingImminentCondition)
    self.singer = singer
    return self
end

function NoResingImminentCondition:is_satisfied(_)
    local singer = self.singer
    if singer:is_burst_underway() then
        return false
    end
    local tracker = singer.song_tracker
    if not tracker or not tracker.is_expiring_soon then
        return true
    end
    local player = singer:get_player()
    if not player then
        return true
    end
    return not tracker:is_expiring_soon(player:get_id(), singer.songs)
end

function NoResingImminentCondition:get_config_items()
    return L{}
end

function NoResingImminentCondition:tostring()
    return "No re-sing imminent"
end

function NoResingImminentCondition.valid_targets()
    return S{ Condition.TargetType.Self }
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
        -- Circuit breaker: after any combo fires, no combo may fire
        -- again for 45 seconds (the firing sequence stamps
        -- 'nitro_attempt'; see nitro_sequence). If a sequence's
        -- abilities fail to land, their recast gates stay open and
        -- the combo would otherwise re-fire the moment the song
        -- hold lapses, re-arming it forever and locking the songs
        -- out. With the latch, a failed burst sings un-boosted and
        -- the next burst, minutes later, tries the combo again.
        conditions:append(GambitCondition.new(CooldownCondition.new('nitro_attempt', 45), GambitTarget.TargetType.Self))
        -- Hold for the next burst: a combo never fires into a burst
        -- already under way (see NoBurstUnderwayCondition). A burst
        -- that started without the combo finishes without it, and
        -- the combo leads the next burst from its first song.
        conditions:append(GambitCondition.new(NoBurstUnderwayCondition.new(singer), GambitTarget.TargetType.Self))
        -- The weaponskill goes first: a combo never fires at or
        -- above the Song Hold TP line (Combat settings, default
        -- 700), the same trip point as the check_gambits song
        -- hold. Firing Nitro first puts the weaponskill in the
        -- middle of the burst it was meant to precede -- it lands
        -- between songs, and a cast fails in its action lock.
        -- Once the weaponskill is spent and TP drops below the
        -- line, the combo leads the burst. The gate also covers
        -- the windows where gambit evaluation runs at the line
        -- (a previous burst still under way), where the
        -- check_gambits hold alone would let a new combo through.
        conditions:append(GambitCondition.new(MaxTacticalPointsCondition.new((singer.song_hold_tp or 700) - 1), GambitTarget.TargetType.Self))
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
            singer.song_tracker:set_all_expiring_soon(true)
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
-- Re-sing fires when the song is up and either its own remaining
-- duration drops below the re-sing duration, or another real song
-- drops below it while this song is inside the join window (the
-- re-sing duration + 160s). Together with the burst marking in
-- check_gambits (which pulls every record to the threshold the
-- moment one song is due), this keeps the burst in song order: on
-- the marking tic the due song's own condition is already true
-- while the marked songs sit exactly at the threshold for a
-- second, and without the shared trigger the due song would jump
-- the queue and lead the burst. The join window stays below a
-- fresh song's duration, so a song the burst just refreshed never
-- re-fires while the rest catch up.
local function build_song_gambits(singer, dummy_song_threshold)
    local dummy_names = singer.dummy_songs:map(function(s) return s:get_name() end)
    local real_song_names = singer.songs:map(function(s) return s:get_name() end)
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
                GambitCondition.new(ConditionalCondition.new(L{
                    SongDurationCondition.new(L{ song:get_name() }, singer.expiring_duration, Condition.Operator.LessThan),
                    ConditionalCondition.new(L{
                        SongDurationCondition.new(real_song_names, singer.expiring_duration, Condition.Operator.LessThan, 1, Condition.Operator.GreaterThanOrEqualTo),
                        SongDurationCondition.new(L{ song:get_name() }, singer.expiring_duration + 160, Condition.Operator.LessThan),
                    }, Condition.LogicalOperator.And),
                }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
            }, song, Condition.TargetType.Self),
        }
    end
    return gambits
end

-- Pianissimo gambits. Two groups:
--   * With ResingMissingSongs on, one Pianissimo gambit per real song,
--     aimed at party members (allies): a member who is missing that
--     song and has a free slot for it gets that one song sung to them.
--     Out of battle only, so a catch-up cast never takes the action
--     queue or swaps the singer's gear mid-fight. Dummy songs are
--     never sung at a member -- they are slot-fillers for the singer's
--     own burst, not songs a member is missing. Real players only:
--     the game never sends a Trust's buffs (no 0x076 packet for
--     Alter Egos), so a Trust's song records are reconstructed from
--     the singer's own casts and cannot be trusted -- in a Trust
--     party the catch-up fired Pianissimo when every Trust already
--     had all five songs. A real player's buffs are reported, so
--     their records are real.
--   * The dedicated Pianissimo songs (e.g. Mage's Ballad III), sung on
--     self or an ally whose job matches the song's job list, once the
--     singer's own set is fully up and no re-sing is imminent. The
--     stock gate for "set first" was a max-songs count on the singer,
--     which reads the same whether the cap is met by the set itself
--     or by dummy songs, and says nothing about a re-sing about to
--     trade the Ballad off the member again. These gambits name the
--     set itself (every real song up on the singer) and hold through
--     bursts and due re-sings (see NoResingImminentCondition), so
--     the Ballad goes out in the stable window after a burst.
local function build_pianissimo_gambits(singer, dummy_gambits, dummy_song_threshold)
    local gambits = L{}
    if singer.resing_missing_songs then
        gambits = singer.songs:map(function(song)
            local song = song:copy()
            song:set_job_abilities(L{ "Pianissimo" })
            song:set_requires_all_job_abilities(true)

            return Gambit.new(GambitTarget.TargetType.Ally, L{
                GambitCondition.new(NotCondition.new(L{ InBattleCondition.new() }), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ IsAlterEgoCondition.new() }), GambitTarget.TargetType.Ally),
                GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), GambitTarget.TargetType.Ally),
                GambitCondition.new(HasMaxNumSongsCondition.new(Condition.Operator.LessThan), GambitTarget.TargetType.Ally),
            }, song, Condition.TargetType.Ally)
        end)
    end

    local set_song_names = singer.songs:map(function(s) return s:get_name() end)
    for song in singer.pianissimo_songs:it() do
        song:set_job_abilities(L{ "Pianissimo" })
        song:set_requires_all_job_abilities(true)

        for targetType in L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }:it() do
            gambits = gambits + L{
                Gambit.new(targetType, L{
                    GambitCondition.new(ModeCondition.new('AutoPianissimoMode', 'Auto'), GambitTarget.TargetType.Self),
                    GambitCondition.new(NotCondition.new(L{ HasSongsCondition.new(L{ song:get_name() }) }), targetType),
                    GambitCondition.new(HasSongsCondition.new(set_song_names), GambitTarget.TargetType.Self),
                    GambitCondition.new(NoResingImminentCondition.new(singer), GambitTarget.TargetType.Self),
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
    self.unit_burst_marked = false

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
    -- next tic once TP drops below the line. Applies between
    -- fights (so the next mob is engaged and the weaponskill
    -- spent before a burst starts) and mid-fight alike. The
    -- debuffer and puller holds trip lower (500 TP by default);
    -- the song line sits at 700 by default so a burst has room
    -- to start before the weaponskill is nearly banked. Both
    -- lines are menu settings (Combat -> Config). Exception: a
    -- Nitro burst already under way sings through -- Nitro is
    -- spent, so that burst finishes first and the weaponskill
    -- waits for it (the spammer holds it; see
    -- Singer:is_nitro_burst_underway). Pausing here would strand
    -- the burst with the Nitro buffs ticking down. The priority
    -- is decided at the line, before a burst starts: the Nitro
    -- combos themselves are gated at the same line (see
    -- build_nitro_gambits), so no burst ever starts over a
    -- banked weaponskill.
    local ffxi_player = windower.ffxi.get_player()
    if ffxi_player and ffxi_player.tp and ffxi_player.tp >= (self.song_hold_tp or 700)
            and not self:is_nitro_burst_underway() then
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
    -- Hold everything while a Nitro sequence is going out. The
    -- sequence's abilities leave one at a time through the shared
    -- action queue, and without this hold the burst's songs queue
    -- between them: the burst starts un-boosted and the remaining
    -- abilities land between songs instead of ahead of Honor March.
    -- The block is set by the sequence's first step (see
    -- nitro_sequence); the action hook releases it into a short
    -- grace the moment the sequence's last ability lands (a cast
    -- attempted in an ability's tail is rejected by the game), and
    -- the timer behind it is only a backstop, so an interrupted
    -- sequence cannot wedge the singer.
    if self.nitro_block_until and os.clock() < self.nitro_block_until then
        return
    end
    -- Burst-as-a-unit marking: the moment any song is due, pull
    -- every song's record down to the re-sing threshold, so the
    -- per-song re-sing gambits refresh the whole set in order as
    -- one burst instead of each song firing on its own clock. The
    -- songs do not share one clock -- Honor March and Victory March
    -- share a buff, so the tracker pairs the two anonymous March
    -- timers to the two songs by expiry order, and which song gets
    -- the short timer flips with packet timing; Marcato also
    -- stretches Honor March past the others. Left to their own
    -- triggers, the bursts split at random. A gambit in the nitro
    -- block does this same marking, but only on a 100-second
    -- cooldown and only when gambit evaluation reaches it; doing
    -- it here, before the gambits are checked, starts the burst
    -- together every time. The latch keeps the songs the burst has
    -- just refreshed (fresh records, full duration) from being
    -- marked again while the rest catch up; it clears once
    -- nothing is expiring, ready for the next cycle.
    if self.song_tracker then
        local player = self:get_player()
        if player then
            local player_id = player:get_id()
            if self.unit_burst_marked then
                if not self.song_tracker:is_expiring_soon(player_id, self.songs) then
                    self.unit_burst_marked = false
                end
            elseif self.song_tracker:is_expiring_soon(player_id, self.songs) then
                self.song_tracker:set_all_expiring_soon(true)
                self.unit_burst_marked = true
            end
        end
    end
    self:check_potency_follow_up()
    return Gambiter.check_gambits(self, gambits, param, ignore_delay)
end

-- Potency follow-up. When ResingMissingSongs is on, a catch-up
-- patch lands on Daurdabla (see the GearSwap rule), so the
-- member's copy of the song is weaker than the burst's. Instead
-- of waiting for the next burst, re-sing that one song to that
-- one member with Pianissimo, on the potency instrument: the
-- member's weak copy is refreshed to full strength and nobody
-- else's songs are touched. Pianissimo's recast is only a few
-- seconds, so a member missing several songs is followed up
-- song by song until none of their copies are weak.
--
-- This is a direct action, not a gambit: a gambit can only aim
-- at "an ally", and the first ally with the song is not
-- necessarily the one whose copy is weak. It runs from
-- check_gambits, after the holds, so the weaponskill hold, the
-- post-weaponskill grace and the Nitro block all gate it too.
-- Real players only, like the catch-up patches: a Trust's
-- records are reconstructed (no 0x076 packet for Alter Egos),
-- and a weak tag on a Trust cannot be trusted.
-- One follow-up at a time, out of battle only, and only while
-- Pianissimo is ready -- without Pianissimo the cast would go
-- out as an area song and overwrite the whole party's timers.
-- A member whose refresh did not land (out of range) keeps the
-- weak record and is retried once the per-song latch passes,
-- instead of re-casting every tic.
function Singer:check_potency_follow_up()
    if not self.resing_missing_songs or not self.song_tracker then
        return
    end
    if self.potency_follow_up_busy_until and os.clock() < self.potency_follow_up_busy_until then
        return
    end
    local ffxi_player = windower.ffxi.get_player()
    if not ffxi_player then
        return
    end
    local player_mob = windower.ffxi.get_mob_by_index(ffxi_player.index)
    if player_mob and player_mob.in_combat then
        return
    end
    -- The readiness condition is stateless apart from the
    -- ability name, so build it once instead of allocating a
    -- new one on every gambit check.
    self.pianissimo_ready_condition = self.pianissimo_ready_condition or JobAbilityRecastReadyCondition.new('Pianissimo')
    if not self.pianissimo_ready_condition:is_satisfied(ffxi_player.index) then
        return
    end
    local player_id = self:get_player():get_id()
    self.potency_follow_up_latch = self.potency_follow_up_latch or {}
    local seen_member_ids = {}
    for party_member in self:get_party():get_party_members(true):it() do
        local member_id = party_member:get_id()
        seen_member_ids[member_id] = true
        local member_mob = party_member:get_mob()
        if member_id ~= player_id and member_mob and not party_member:is_trust() then
            for song in self.songs:it() do
                local song_id = song:get_spell().id
                local key = member_id .. ':' .. song_id
                local latched = self.potency_follow_up_latch[key]
                local is_weak = self.song_tracker:has_weak_song(member_id, song_id)
                if not is_weak and latched then
                    -- The copy has been refreshed (or the record
                    -- is gone): the retry latch has done its job,
                    -- so drop the entry instead of keeping it for
                    -- the rest of the session.
                    self.potency_follow_up_latch[key] = nil
                    latched = nil
                end
                if is_weak
                        and not (latched and os.clock() - latched < 30) then
                    local follow_up = song:copy()
                    follow_up:set_job_abilities(L{ 'Pianissimo' })
                    follow_up:set_requires_all_job_abilities(true)
                    -- Tell GearSwap this Pianissimo cast is a
                    -- refresh, not a patch, so it keeps the
                    -- potency instrument instead of equipping
                    -- Daurdabla (see BRD.lua's potencyfollowup
                    -- command). The command action goes out
                    -- first, in the same tic, so the arm is set
                    -- before the cast starts.
                    self.action_queue:push_action(CommandAction.new(0, 0, 0, '/console gs c potencyfollowup'), true)
                    local action = follow_up:to_action(member_mob.index, self:get_player())
                    action.priority = ActionPriority.high
                    self.action_queue:push_action(action, true)
                    self.potency_follow_up_latch[key] = os.clock()
                    self.potency_follow_up_busy_until = os.clock() + 15
                    return
                end
            end
        end
    end
    -- Drop latch entries for members who have left the party,
    -- so the latch stays bounded by the current party's songs.
    for key in pairs(self.potency_follow_up_latch) do
        local latched_member_id = tonumber(string.match(key, '^(%d+):'))
        if not latched_member_id or not seen_member_ids[latched_member_id] then
            self.potency_follow_up_latch[key] = nil
        end
    end
end

-------
-- Returns whether a burst is currently under way: a song cast is
-- running right now, or any song on the player landed within the
-- last BURST_ACTIVE_WINDOW seconds. Between the songs of a burst
-- the singer is not casting, so the fresh records are what show the
-- burst is unfinished; between bursts every record is minutes old.
-- The Nitro combos hold while this is true (see
-- NoBurstUnderwayCondition), so a combo that comes off cooldown
-- mid-burst leads the next burst instead of boosting only the
-- current one's remaining songs.
-- @treturn boolean True if a burst is under way
function Singer:is_burst_underway()
    if self:get_is_singing() then
        return true
    end
    if not self.song_tracker or not self.song_tracker.get_songs then
        return false
    end
    local player = self:get_player()
    if not player then
        return false
    end
    local songs = self.song_tracker:get_songs(player:get_id())
    if not songs then
        return false
    end
    for song_record in songs:it() do
        if song_record.created_time and os.time() - song_record.created_time < BURST_ACTIVE_WINDOW then
            return true
        end
    end
    return false
end

-------
-- Returns whether a Nitro burst is under way: the combo's abilities
-- are still going out (the nitro block), or Nitro is up and the
-- burst it led still has songs to sing. Once Nitro is spent, the
-- burst owns the fight until it finishes -- check_gambits does not
-- pause it for a banked weaponskill, and the spammer holds the
-- weaponskill until the burst completes. The hold is bounded by
-- Nitro's own duration: if the burst cannot finish, it releases
-- when the buffs wear off.
-- @treturn boolean True while a Nitro burst is under way
function Singer:is_nitro_burst_underway()
    if self.nitro_block_until and os.clock() < self.nitro_block_until then
        return true
    end
    if self.job and self.job.is_nitro_active and self.job:is_nitro_active() then
        return self:has_songs_pending()
    end
    return false
end

-------
-- Returns whether a burst is still pending: a burst has not run yet
-- (no configured songs up), one is under way, or the songs are close
-- to expiring. The singer is only "active" while a cast is running,
-- so between the songs of a burst get_is_singing() reads false even
-- though the burst is unfinished; the puller uses this to avoid
-- claiming a mob in those gaps, so a burst always finishes before a
-- claim. False when the auto singer is off, when there is no tracker
-- yet, or when every song is up with time to spare.
--
-- A partial loss is different: when one song of a full set drops
-- mid-cycle (it expired early, or was overwritten), the singer
-- deliberately leaves it until the next burst -- at the song cap a
-- refill would knock out another real song. Counting it as pending
-- would hold every claim and engage for the rest of the cycle, so a
-- partial loss only counts while a burst is actually under way (a
-- record from the last minute) or the remaining songs are about to
-- expire anyway, which is when the burst that restores it runs.
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
    local num_missing = 0
    for song in self.songs:it() do
        if not self.song_tracker:has_song(player_id, song:get_spell().id) then
            num_missing = num_missing + 1
        end
    end
    if num_missing == 0 then
        return self.song_tracker:is_expiring_soon(player_id, self.songs)
    end
    if num_missing >= self.songs:length() then
        return true
    end
    local records = self.song_tracker:get_songs(player_id)
    if records then
        for song_record in records:it() do
            if song_record.created_time and os.time() - song_record.created_time < 60 then
                return true
            end
        end
    end
    return self.song_tracker:is_expiring_soon(player_id, self.songs)
end

-------
-- Forwards the per-second tic to the song tracker so its expiration sweep
-- actually runs (Trust:tic calls role:tic when it exists). Tracked job
-- ability uses are recorded from the action packet when they land (see
-- on_add); this tic is the fallback for a use made while Trust was off,
-- recognised by its buff still being up when Trust returns. The stamp
-- is written once per activation: while the buff stays up, an existing
-- stamp is left alone until it is older than the ability's own recast.
-- Re-stamping as the buff ages would start the cooldown from the
-- buff's last sighting instead of the use, leaving Trust's clock
-- behind the game's — a burst that lands right as the real recasts
-- clear would then start without the Nitro combo, which would slip
-- in mid-burst once the clock caught up.
function Singer:tic(_, _)
    if self.song_tracker then
        self.song_tracker:tic()
    end
    local player = windower.ffxi.get_player()
    if player and self.job then
        local now = os.time()
        for ja in TRACKED_JAS:it() do
            local is_active = self.job[ja.is_active]
            if type(is_active) == 'function' and is_active(self.job) then
                local last_use = CooldownCondition.get_timestamp(ja.key)
                if not last_use or now - last_use >= ja.recast then
                    record_ja_use(self, ja, now)
                end
            end
        end
    end
end

function Singer:on_add()
    Gambiter.on_add(self)

    -- Watch the player's own action packets: a weaponskill landing
    -- (category 3) starts the 2-second post-weaponskill song hold in
    -- check_gambits, and a tracked job ability landing (category 6,
    -- whose param is the ability id) records that ability's use at
    -- the exact moment it happens -- the timestamp every recast gate
    -- reads, for Trust's own uses and the player's manual ones alike.
    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        local player = windower.ffxi.get_player()
        if not player or act.actor_id ~= player.id then return end
        if act.category == 3 then
            self.last_weaponskill_time = os.clock()
        elseif act.category == 6 then
            local ja = TRACKED_JA_BY_ID[act.param]
            if ja then
                record_ja_use(self, ja, os.time())
                -- The tracker tags the next song record created as
                -- the one Marcato rode on, so its duration pairing
                -- can tell the two Marches' timers apart (Marcato
                -- stretches its song past its same-buff partner,
                -- which otherwise swaps their timers for a cycle).
                if ja.key == 'marcato' and self.song_tracker and self.song_tracker.note_marcato_used then
                    self.song_tracker:note_marcato_used()
                end
                -- If this was the last ability of a Nitro sequence
                -- still holding the burst's songs, release the hold
                -- now instead of waiting out the backstop timer --
                -- into a short grace rather than clearing it: the
                -- game rejects a cast attempted in the tail of an
                -- ability ("Unable to cast at this time"), so the
                -- first song waits out the ability lockout and goes
                -- out clean instead of failing once and retrying.
                if self.nitro_block_jas and self.nitro_block_jas[ja.key] then
                    self.nitro_block_jas[ja.key] = nil
                    if next(self.nitro_block_jas) == nil then
                        self.nitro_block_jas = nil
                        self.nitro_block_until = os.clock() + 2
                    end
                end
            end
        end
    end), WindowerEvents.Action)

    CooldownCondition.set_timestamp('resing_songs', os.time())

    -- Seed the Nitro attempt latch in the past so the combos start
    -- allowed: a CooldownCondition whose key was never stamped is
    -- never satisfied, so without this the latch would bar every
    -- combo forever instead of only in the 45 seconds after one
    -- fires.
    CooldownCondition.set_timestamp('nitro_attempt', 0)

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
    self.song_settings = song_settings
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

-- Menu-adjustable song hold, from the Combat settings (Trust
-- menu -> Combat -> Config -> Song Hold TP). At or above this
-- much TP the songs wait for the weaponskill, and the Nitro
-- combos only fire below it. The default reproduces the fixed
-- 700 line for settings files that predate the key. Changing it
-- rebuilds the gambits so the Nitro gate moves with the hold.
function Singer:set_combat_settings(combat_settings)
    combat_settings = combat_settings or {}
    self.song_hold_tp = combat_settings.SongHoldTP or 700
    if self.song_settings then
        self:set_song_settings(self.song_settings)
    end
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
