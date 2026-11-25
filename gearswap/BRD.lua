-- ============================================================
--  BRD.lua - Bard TP + Weaponskill + Song GearSwap
--  BRD-30
--  BRD-29 plus one change: a new real song with no
--  dummy to overwrite, Clarion Call up, and 3+ songs
--  already active is sung with Daurdabla (see
--  equip_song). Without it that cast overwrote the
--  oldest song instead of becoming the 5th, and the
--  singer chased the missing song in a loop.
--  BRD-29
--  BRD-28 with the debug prints removed. The diagnostic
--  pull confirmed the timing is correct: Elegy and Requiem
--  VII both reach aftercast, and tp_retry equips TP gear
--  4s after the last song finishes. Same logic as BRD-27.
--  BRD-27
--  BRD-26 plus one change: return_tp (the weaponskill
--  return) no longer swaps to TP gear on the spot. If you
--  have TP ready, the auto-WS can fire right after the
--  Elegy claim, and return_tp used to equip TP gear 2s
--  later even while the follow-up debuff song was being
--  cast -- the flicker to TP, back to song gear, back to
--  TP. Now return_tp hands off to the tp_retry wait
--  instead, which only equips TP once no song has
--  finished for SONG_RETURN_DELAY and no song is mid-cast.
--  BRD-25 plus one change: engaging now ALWAYS defers to the
--  tp_retry wait instead of swapping to TP gear on the spot.
--  BRD-25 only held TP gear back when a song had finished
--  within SONG_RETURN_DELAY, but the engage can fire before
--  aftercast updates LAST_SONG_TIME (race), so the check saw
--  a stale timestamp and swapped to TP gear right after the
--  Elegy claim anyway, then back to song gear for the debuff.
--  Now engaging just starts the tp_retry chain (which waits
--  1s before its first check, by which time aftercast has
--  run), and tp_retry equips TP only once no song has
--  finished for SONG_RETURN_DELAY and no song is mid-cast.
--  BRD-24 plus one change: engaging a mob no longer forces
--  TP gear right away if a song just finished. After the
--  Puller claims with Carnage Elegy, the Bard used to swap
--  to TP gear the instant it engaged, before the follow-up
--  debuff song was even cast. Now engaging starts the same
--  tp_retry wait instead: TP gear only comes back once no
--  song has finished for SONG_RETURN_DELAY seconds and no
--  song is mid-cast, so Elegy and the debuff after it both
--  land in song gear first.
--  BRD-23 plus one change: Daurdabla is now ONLY for the
--  two dummy songs (Goblin Gavotte, Scop's Operetta).
--  Real songs always keep their potency instrument
--  (Gjallarhorn, Marsyas for Honor March). BRD-23 still
--  put a real song on Daurdabla when no dummy was active
--  and the song count was at the limit, so Minuet IV and
--  Minuet V landed weak whenever they were re-sung after
--  expiring with the dummies down, and with the potency
--  re-sing disabled nothing fixed them afterwards.
--  Based on BRD-21, with one change:
--  BRD-21 switched to Daurdabla for every new song once 2
--  songs were up, so Minuet III, IV and V all landed weak
--  and had to be re-sung with Gjallarhorn. BRD-22 only
--  uses Daurdabla for the dummy songs (Goblin Gavotte,
--  Scop's Operetta) and for a new real song when there is
--  no dummy to overwrite and no room left under
--  Gjallarhorn (3 songs with Clarion Call up, buff 499,
--  else 2). Every real song in the burst -- Honor March
--  (Marsyas), Madrigal, Minuet III, IV, V -- now lands
--  with its potency instrument the first time, so no
--  re-sing is needed.
--  Refreshes still keep Gjallarhorn (Marsyas for Honor
--  March), as in BRD-21.
--
--  FLOW
--    * TP gear is no longer forced right after a kill. It only
--      equips when you actually start the next fight (Engaged)
--      or when you run //gs c tp.
--    * After a song, TP gear does NOT come back right away.
--      It waits until you have finished singing -- no song
--      for SONG_RETURN_DELAY seconds -- and only then, if
--      you are still Engaged. So you can sing all your buffs
--      back to back and the gear stays on song gear until
--      the last one is done. Idle (buffing before a pull,
--      or after a kill) you stay in song gear until you
--      engage / pull.
--    * After a weaponskill, TP gear comes back after 2 seconds,
--      but only if you are still Engaged. If the WS killed the
--      mob, you stay in WS gear until you pull / engage again.
--    * The pulling set is ELEGY_SET: //gs c pull equips the
--      Carnage Elegy set, not TP gear.
--
--  HOW TO CHANGE GEAR:
--    Edit ONLY the section below, between the EDIT HERE lines.
--    Each set lists every slot, one per line.
--    Change just the name in quotes, save, then in game:
--      //gs r
--    You do not need to touch anything below that section.
--
--  INSTALL:
--    Copy this file to: Windower/addons/gearswap/data/BRD.lua
--    In game: //gs r
-- ============================================================

-- ================= EDIT HERE ONLY =================

-- ---- Settings ----

-- Seconds to wait in WS gear before switching back to TP gear.
WS_RETURN_DELAY = 2

-- Seconds of not singing before TP gear comes back after
-- a song. The file cannot count how many songs you will
-- sing, so it waits for this long with no song finishing
-- and then switches back. Raise it (e.g. to 5) if you sing
-- with long pauses between songs, lower it (e.g. to 2) if
-- TP gear feels slow to come back after your last song.
SONG_RETURN_DELAY = 4

-- When the last song finished. Do not edit, the file updates it.
LAST_SONG_TIME = 0

-- True while a tp_retry check is already waiting to run.
-- Do not edit, the file updates it. This is the leak guard:
-- without it, every song you sing queues its own retry
-- chain, and the chains pile up while you keep singing.
-- With it, there is ever at most one chain running.
TP_RETRY_PENDING = false

-- ---- Capes and instrument ----

-- Mordant Rime weaponskill cape.
Mordant_CAPE = {
    name = "Intarabus's Cape",
    augments = {'CHR+20', 'Accuracy+20 Attack+20', 'Weapon skill damage +10%',},
}

-- Rudra's Storm / Evisceration weaponskill cape (your DD cape).
-- Augments copied exactly from your //gs export, including
-- '"Dbl.Atk."+10' - GearSwap uses that short form, not "Double Attack".
RUDRA_CAPE = {
    name = "Intarabus's Cape",
    augments = {'DEX+20', 'Accuracy+20 Attack+20', 'Accuracy+10', '"Dbl.Atk."+10', 'Damage taken-5%',},
}

-- Savage Blade weaponskill cape.
-- Intarabus's Cape, STR split across two lines (STR+20 and
-- STR+10), exactly as in your //gs export.
SAVAGE_CAPE = {
    name = "Intarabus's Cape",
    augments = {'STR+20', 'Accuracy+20 Attack+20', 'STR+10', 'Weapon skill damage +10%', 'Damage taken-5%',},
}

-- Song cape. A different Intarabus's Cape from the WS ones above.
SONG_CAPE = {
    name = "Intarabus's Cape",
    augments = {'CHR+20', 'Mag. Acc+20 /Mag. Dmg.+20', '"Fast Cast"+10', 'Damage taken-5%',},
}

-- TP instrument (range slot).
-- Quadruple Attack is written +3 here, with no % sign, matching
-- other BRD GearSwap Linos sets. If this Linos does not equip in game,
-- try changing that one line to 'Quadruple Attack +3%' and reload.
TP_LINOS = {
    name = "Linos",
    augments = {'Accuracy+20', '"Store Tp"+4', 'Quadruple Attack +3',},
}

-- Weaponskill instrument (range slot) for Savage Blade.
-- STR+8 Linos, for Savage Blade only. TP, Mordant, Rudra
-- and Evisceration still use TP_LINOS above.
WS_LINOS = {
    name = "Linos",
    augments = {'STR+8', 'Attack+20', 'Weapon skill damage +3%',},
}

-- ---- TP set ----

TP_SET = {
    main  = "Naegling",
    sub   = "Centovente",
    range = TP_LINOS,
    head  = "Null Masque",
    neck  = "Bard's Charm +2",
    ear1  = "Telos Earring",
    ear2  = "Dedition Earring",
    body  = "Ashera Harness",
    hands = "Nyame Gauntlets",
    ring1 = "Chirich Ring +1",
    ring2 = "Chirich Ring +1",
    back  = "Null Shawl",
    waist = "Sailfi Belt +1",
    legs  = "Nyame Flanchard",
    feet  = "Nyame Sollerets",
}

-- ---- Weaponskill sets ----

-- Mordant Rime set. CHR 70% / DEX 30%.
MORDANT_SET = {
    main  = "Carnwenhan",
    sub   = "Gleti's knife",
    range = TP_LINOS,
    head  = "Nyame Helm",
    neck  = "Bard's Charm +2",
    ear1  = "Moonshade Earring",
    ear2  = "Hoxne Earring",
    body  = "Bihu justaucorps +4",
    hands = "Nyame Gauntlets",
    ring1 = "Cornelia's Ring",
    ring2 = "Metamorph Ring +1",
    back  = Mordant_CAPE,
    waist = "Sailfi Belt +1",
    legs  = "Nyame Flanchard",
    feet  = "Nyame Sollerets",
}

-- Rudra's Storm set. DEX 80%.
RUDRA_SET = {
    main  = "Carnwenhan",
    sub   = "Gleti's knife",
    range = TP_LINOS,
    head  = "Nyame Helm",
    neck  = "Bard's Charm +2",
    ear1  = { name = "Moonshade Earring", augments = {'TP Bonus+250'} },
    ear2  = "Hoxne Earring",
    body  = "Bihu justaucorps +4",
    hands = "Nyame Gauntlets",
    ring1 = "Metamorph Ring +1",
    ring2 = "Ilabrat Ring",
    back  = RUDRA_CAPE,
    waist = "Kentarch Belt +1",
    legs  = "Nyame Flanchard",
    feet  = "Nyame Sollerets",
}

-- Evisceration set. DEX dagger WS, same as Rudra's Storm, same DD cape.
EVISCERATION_SET = {
    main  = "Carnwenhan",
    sub   = "Gleti's knife",
    range = TP_LINOS,
    head  = "Nyame Helm",
    neck  = "Bard's Charm +2",
    ear1  = { name = "Moonshade Earring", augments = {'TP Bonus+250'} },
    ear2  = "Hoxne Earring",
    body  = "Nyame mail",
    hands = "Nyame Gauntlets",
    ring1 = "Metamorph Ring +1",
    ring2 = "Ilabrat Ring",
    back  = RUDRA_CAPE,
    waist = "Fotia Belt",
    legs  = "Nyame Flanchard",
    feet  = "Nyame Sollerets",
}

-- Savage Blade set. STR/MND sword WS.
SAVAGE_SET = {
    main  = "Naegling",
    sub   = "Centovente",
    range = WS_LINOS,
    head  = "Nyame Helm",
    neck  = "Republican platinum medal",
    ear1  = "Moonshade Earring",
    ear2  = "Ishvara earring",
    body  = "Bihu justaucorps +4",
    hands = "Nyame Gauntlets",
    ring1 = "Cornelia's Ring",
    ring2 = "Sroda Ring",
    back  = SAVAGE_CAPE,
    waist = "Sailfi Belt +1",
    legs  = "Nyame Flanchard",
    feet  = "Nyame Sollerets",
}

-- ---- Song set ----

-- Used for all Bard songs in precast and midcast.
-- Range is Gjallarhorn here. Honor March is the exception:
-- the code below swaps the range to Marsyas for Honor March only.
SONG_SET = {
    main  = "Carnwenhan",
    sub   = "Kali",
    range = "Gjallarhorn",
    head  = "Fili Calot +3",
    neck  = "Moonbow Whistle +1",
    ear1  = "Regal Earring",
    ear2  = "Fili Earring +1",
    body  = "Fili Hongreline +3",
    hands = "Brioso Cuffs +4",
    ring1 = "Stikini Ring +1",
    ring2 = "Stikini Ring +1",
    back  = SONG_CAPE,
    waist = "Embla Sash",
    legs  = "Inyanga Shalwar +2",
    feet  = "Brioso Slippers +3",
}

-- ---- Carnage Elegy set ----

-- Used for Carnage Elegy only, in precast and midcast,
-- and as the pulling set: //gs c pull equips this set.
-- Carnage Elegy is a set-potency Slow (50% cap), so this
-- set is built to LAND it and make it last, not for potency:
-- Magic Accuracy / Singing skill / CHR first, then Song
-- duration. Gjallarhorn stays as range (All Songs +4).
-- Head is Bihu Roundlet +3, ear1 is Regal Earring,
-- ear2 is Fili Earring +1, sub is Ammurapi Shield,
-- waist is Acuity Belt +1, body is Fili Hongreline +3.
ELEGY_SET = {
    main  = "Carnwenhan",
    sub   = "Ammurapi Shield",
    range = "Gjallarhorn",
    head  = "Bihu Roundlet +3",
    neck  = "Moonbow Whistle +1",
    ear1  = "Regal Earring",
    ear2  = "Fili Earring +1",
    body  = "Fili Hongreline +3",
    hands = "Brioso Cuffs +4",
    ring1 = "Stikini Ring +1",
    ring2 = "Stikini Ring +1",
    back  = SONG_CAPE,
    waist = "Acuity Belt +1",
    legs  = "Inyanga Shalwar +2",
    feet  = "Brioso Slippers +3",
}

-- ================= DO NOT EDIT BELOW =================

function get_sets()
    sets = {}
    sets.TP = TP_SET
    sets.precast = {}
    sets.precast.WS = {}
    sets.precast.WS['Mordant Rime'] = MORDANT_SET
    sets.precast.WS["Rudra's Storm"] = RUDRA_SET
    sets.precast.WS['Evisceration'] = EVISCERATION_SET
    sets.precast.WS['Savage Blade'] = SAVAGE_SET
    sets.precast.BardSong = SONG_SET
    sets.midcast = {}
    sets.midcast.BardSong = SONG_SET
end

function user_setup()
    equip(sets.TP)
    windower.add_to_chat(207, 'BRD: TP gear equipped on load, range should be Linos.')
end

-- Count how many Bard songs are currently active on you.
-- Song buffs are IDs 195-223 (the same set Trust uses).
-- The game checks the song limit when a new song lands,
-- against the instrument you have equipped at that moment.
function count_active_songs()
    local n = 0
    if player and player.buffs then
        for _, buff_id in ipairs(player.buffs) do
            if buff_id >= 195 and buff_id <= 223 then
                n = n + 1
            end
        end
    end
    return n
end

-- Song name -> buff id, taken from Windower's res/spells.lua
-- (checked 2026-11-18). Songs that give the same effect share
-- one buff id (all Minuets are 198, all Marches are 214).
-- This table replaces a res.spells lookup: GearSwap user files
-- do NOT get a `res` global (see GearSwap refresh.lua user_env),
-- so the BRD-20 version of is_song_active always returned false
-- and every refresh sang with Daurdabla instead of Gjallarhorn
-- or Marsyas. player.buffs IS available to user files.
local SONG_BUFF_IDS = {
    ["Advancing March"] = 214,
    ["Adventurer's Dirge"] = 221,
    ["Archer's Prelude"] = 200,
    ["Aria of Passion"] = 213,
    ["Army's Paeon"] = 195,
    ["Army's Paeon II"] = 195,
    ["Army's Paeon III"] = 195,
    ["Army's Paeon IV"] = 195,
    ["Army's Paeon V"] = 195,
    ["Army's Paeon VI"] = 195,
    ["Army's Paeon VII"] = 195,
    ["Army's Paeon VIII"] = 195,
    ["Battlefield Elegy"] = 194,
    ["Bewitching Etude"] = 215,
    ["Blade Madrigal"] = 199,
    ["Cactuar Fugue"] = 211,
    ["Carnage Elegy"] = 194,
    ["Chocobo Hum"] = 204,
    ["Chocobo Mazurka"] = 219,
    ["Dark Carol"] = 216,
    ["Dark Carol II"] = 216,
    ["Dark Threnody"] = 217,
    ["Dark Threnody II"] = 217,
    ["Devotee Serenade"] = 208,
    ["Dextrous Etude"] = 215,
    ["Dragonfoe Mambo"] = 201,
    ["Earth Carol"] = 216,
    ["Earth Carol II"] = 216,
    ["Earth Threnody"] = 217,
    ["Earth Threnody II"] = 217,
    ["Enchanting Etude"] = 215,
    ["Fire Carol"] = 216,
    ["Fire Carol II"] = 216,
    ["Fire Threnody"] = 217,
    ["Fire Threnody II"] = 217,
    ["Foe Lullaby"] = 2,
    ["Foe Lullaby II"] = 2,
    ["Foe Requiem"] = 192,
    ["Foe Requiem II"] = 192,
    ["Foe Requiem III"] = 192,
    ["Foe Requiem IV"] = 192,
    ["Foe Requiem V"] = 192,
    ["Foe Requiem VI"] = 192,
    ["Foe Requiem VII"] = 192,
    ["Foe Requiem VIII"] = 192,
    ["Foe Sirvente"] = 220,
    ["Fowl Aubade"] = 202,
    ["Goblin Gavotte"] = 210,
    ["Goddess's Hymnus"] = 218,
    ["Gold Capriccio"] = 207,
    ["Herb Pastoral"] = 203,
    ["Herculean Etude"] = 215,
    ["Honor March"] = 214,
    ["Horde Lullaby"] = 2,
    ["Horde Lullaby II"] = 2,
    ["Hunter's Prelude"] = 200,
    ["Ice Carol"] = 216,
    ["Ice Carol II"] = 216,
    ["Ice Threnody"] = 217,
    ["Ice Threnody II"] = 217,
    ["Jester's Operetta"] = 206,
    ["Knight's Minne"] = 197,
    ["Knight's Minne II"] = 197,
    ["Knight's Minne III"] = 197,
    ["Knight's Minne IV"] = 197,
    ["Knight's Minne V"] = 197,
    ["Learned Etude"] = 215,
    ["Light Carol"] = 216,
    ["Light Carol II"] = 216,
    ["Light Threnody"] = 217,
    ["Light Threnody II"] = 217,
    ["Lightning Carol"] = 216,
    ["Lightning Carol II"] = 216,
    ["Logical Etude"] = 215,
    ["Ltng. Threnody"] = 217,
    ["Ltng. Threnody II"] = 217,
    ["Mage's Ballad"] = 196,
    ["Mage's Ballad II"] = 196,
    ["Mage's Ballad III"] = 196,
    ["Maiden's Virelai"] = 14,
    ["Massacre Elegy"] = 194,
    ["Pining Nocturne"] = 223,
    ["Puppet's Operetta"] = 206,
    ["Quick Etude"] = 215,
    ["Raptor Mazurka"] = 219,
    ["Sage Etude"] = 215,
    ["Scop's Operetta"] = 206,
    ["Sentinel's Scherzo"] = 222,
    ["Sheepfoe Mambo"] = 201,
    ["Shining Fantasia"] = 205,
    ["Sinewy Etude"] = 215,
    ["Spirited Etude"] = 215,
    ["Swift Etude"] = 215,
    ["Sword Madrigal"] = 199,
    ["Uncanny Etude"] = 215,
    ["Valor Minuet"] = 198,
    ["Valor Minuet II"] = 198,
    ["Valor Minuet III"] = 198,
    ["Valor Minuet IV"] = 198,
    ["Valor Minuet V"] = 198,
    ["Victory March"] = 214,
    ["Vital Etude"] = 215,
    ["Vivacious Etude"] = 215,
    ["Warding Round"] = 209,
    ["Water Carol"] = 216,
    ["Water Carol II"] = 216,
    ["Water Threnody"] = 217,
    ["Water Threnody II"] = 217,
    ["Wind Carol"] = 216,
    ["Wind Carol II"] = 216,
    ["Wind Threnody"] = 217,
    ["Wind Threnody II"] = 217,
}


-- Returns whether the song being cast is already active on
-- you. A song that is already active is being refreshed,
-- not added: refreshing does not need a new song slot, so
-- it can be sung with the potency instrument (Gjallarhorn
-- / Marsyas) even when you already have 5 songs up.
-- Looks the buff id up in SONG_BUFF_IDS above and checks
-- player.buffs; no `res` needed. Songs that land on the
-- enemy (Carnage Elegy, Requiem, Lullaby) are never in
-- player.buffs, so they correctly count as not active.
function is_song_active(spell)
    local buff_id = spell.name and SONG_BUFF_IDS[spell.name]
    if not buff_id then
        return false
    end
    if player and player.buffs then
        for _, id in ipairs(player.buffs) do
            if id == buff_id then
                return true
            end
        end
    end
    return false
end

-- Clarion Call buff id (Windower res/buffs.lua; Trust's
-- Bard:is_clarion_call_active checks the same buff). While
-- it is up, Gjallarhorn holds 3 songs instead of 2.
local CLARION_CALL_BUFF_ID = 499

-- Returns whether Clarion Call is active on you.
function is_clarion_call_active()
    if player and player.buffs then
        for _, id in ipairs(player.buffs) do
            if id == CLARION_CALL_BUFF_ID then
                return true
            end
        end
    end
    return false
end

-- Pianissimo buff id (Windower res/buffs.lua). While it
-- is up, the next song lands on one party member only.
local PIANISSIMO_BUFF_ID = 409

-- Returns whether Pianissimo is active on you.
function is_pianissimo_active()
    if player and player.buffs then
        for _, id in ipairs(player.buffs) do
            if id == PIANISSIMO_BUFF_ID then
                return true
            end
        end
    end
    return false
end

-- Dummy song buff ids (SONG_BUFF_IDS above): Goblin Gavotte
-- is 210, Scop's Operetta is 206. Only the two dummy
-- songs are ever sung with Daurdabla.
function is_dummy_song_active()
    if player and player.buffs then
        for _, id in ipairs(player.buffs) do
            if id == 210 or id == 206 then
                return true
            end
        end
    end
    return false
end

-- One place for song gear, used by precast and midcast.
-- Carnage Elegy gets its own set, Honor March gets Marsyas,
-- every other song gets the normal SONG_SET.
-- Daurdabla is only for the dummy songs, for a new real
-- song when there is no dummy to overwrite and no room left
-- under Gjallarhorn, and for Pianissimo patch casts (see
-- the end of this function). Every real song in the 5-song burst
-- lands with its potency instrument the first time, so
-- none of them needs a potency re-sing:
--   Honor March (Marsyas) / Madrigal / Minuet III: 0-2
--   songs up, room under the potency instrument (3 with
--   Clarion Call, 2 without).
--   Dummies: Daurdabla, they only hold the extra slots.
--   Minuet IV / V: a dummy is up, so they overwrite it.
-- A new real song with 3+ songs up and no dummy active
-- still needs Daurdabla for the slot (e.g. re-singing a
-- song that fully expired); the Trust potency gambit
-- re-sings it with Gjallarhorn afterwards.
-- Refreshing a song that is already active needs no new
-- slot, so it keeps the potency instrument above
-- and is sung with Gjallarhorn (Marsyas for Honor March).
function equip_song(spell)
    if spell.name == 'Carnage Elegy' then
        equip(ELEGY_SET)
    else
        equip(SONG_SET)
        if spell.name == 'Honor March' then
            equip({range = "Marsyas"})
        end
    end
    -- Daurdabla is for the two dummy songs, and for one
    -- recovery case: a new real song with no dummy to
    -- overwrite while Clarion Call is up and 3+ songs are
    -- already active. The game checks the song limit
    -- against the instrument equipped when the song
    -- lands -- 3 under Gjallarhorn with Clarion Call --
    -- so that cast on the potency instrument overwrites
    -- the oldest song instead of becoming the 5th, and
    -- re-singing the overwritten song overwrites the
    -- next one: the singer loops and the set never
    -- reaches 5. With Daurdabla the limit is 5 and the
    -- song lands; it is weaker for it, and the next
    -- burst's refresh restores its potency instrument.
    -- Real songs otherwise always keep their potency
    -- instrument (Gjallarhorn, Marsyas for Honor March),
    -- even when no dummy is up: Minuet IV and Minuet V
    -- were landing on Daurdabla whenever they were sung
    -- with no dummy active (e.g. re-sung after they
    -- expired), and with the potency re-sing disabled
    -- there was nothing to fix them afterwards, so they
    -- stayed weak.
    if not is_song_active(spell) then
        if spell.name == "Goblin Gavotte" or spell.name == "Scop's Operetta" then
            equip({range = "Daurdabla"})
        elseif is_clarion_call_active() and not is_dummy_song_active() and count_active_songs() >= 3 then
            equip({range = "Daurdabla"})
        end
    end
    -- A Pianissimo cast is a patch: Trust only sings one at
    -- a party member who is missing that song (the Resing
    -- Missing Songs catch-up, or a dedicated Pianissimo
    -- song), and the member may already hold songs the
    -- patch has to fit beside. Under Gjallarhorn the limit
    -- is 2 (3 with Clarion Call), so the patch would
    -- overwrite the member's oldest song instead of adding
    -- the missing one. On Daurdabla the limit is 4 (5 with
    -- Clarion Call) and the song lands in the free slot;
    -- it is weaker for it, and the next burst's refresh
    -- restores its potency instrument. This cannot key off
    -- is_song_active: that reads your own songs, and you
    -- usually already have the patched song yourself.
    if is_pianissimo_active() then
        equip({range = "Daurdabla"})
    end
end

function precast(spell)
    if spell.type == 'WeaponSkill' then
        if sets.precast.WS[spell.name] then
            equip(sets.precast.WS[spell.name])
        else
            equip(sets.precast.WS['Mordant Rime'])
        end
    elseif spell.type == 'BardSong' then
        equip_song(spell)
    end
end

function midcast(spell)
    if spell.type == 'BardSong' then
        equip_song(spell)
    end
end

function aftercast(spell)
    if spell.type == 'WeaponSkill' then
        -- Still scheduled, but return_tp below only equips TP
        -- if you are still Engaged. If the WS killed the mob,
        -- you stay in WS gear until you pull / engage again.
        windower.send_command('wait ' .. WS_RETURN_DELAY .. '; gs c return_tp')
    elseif spell.type == 'BardSong' then
        -- Do NOT switch back to TP gear here. Just note when
        -- this song finished and check again in 1 second.
        -- tp_retry (below) only equips TP once you have
        -- stopped singing for SONG_RETURN_DELAY seconds,
        -- so all your songs go off before the gear swaps.
        -- Only start a check chain if one is not already
        -- running, so singing 5 songs does not queue 5 chains.
        LAST_SONG_TIME = os.time()
        if not TP_RETRY_PENDING then
            TP_RETRY_PENDING = true
            windower.send_command('wait 1; gs c tp_retry')
        end
    end
end

function status_change(new_status, old_status)
    -- TP gear only when you actually engage a mob.
    -- Going Idle after a kill no longer forces TP gear.
    -- Never swap to TP gear right here on engage. After the
    -- Puller claims with Carnage Elegy, the engage can fire
    -- before aftercast updates LAST_SONG_TIME, so a check here
    -- would see a stale timestamp and swap to TP gear right
    -- after the Elegy, then back to song gear for the debuff
    -- that follows. Instead always start the tp_retry wait:
    -- it waits 1s before its first check (by which time
    -- aftercast has run), then equips TP only once no song
    -- has finished for SONG_RETURN_DELAY seconds and no song
    -- is mid-cast. If no song was cast, the first check
    -- passes at once, so TP gear is only ~1s late. If a retry
    -- chain is already running, it will handle it.
    if new_status == 'Engaged' then
        if not TP_RETRY_PENDING then
            TP_RETRY_PENDING = true
            windower.send_command('wait 1; gs c tp_retry')
        end
    end
end

-- Manual commands:
--   //gs c tp      - force TP gear (with Linos) right now
--   //gs c pull    - equip the Carnage Elegy pulling set
--   //gs c marsyas - equip Marsyas only (for Honor March, etc.)
--   //gs c honor   - equip Marsyas, wait 1 second, sing Honor March
function self_command(command)
    if command == 'return_tp' then
        -- Do NOT swap to TP gear here. If you had TP ready,
        -- the auto-WS can fire right after the Elegy claim,
        -- and this used to equip TP gear 2s later even while
        -- the follow-up debuff song was being cast -- the
        -- flicker to TP, back to song gear, back to TP. Hand
        -- off to the tp_retry wait instead: it only equips TP
        -- once no song has finished for SONG_RETURN_DELAY and
        -- no song is mid-cast. If no song was cast, the first
        -- check passes at once, so TP gear is only ~1s late.
        if player.status == 'Engaged' then
            if not TP_RETRY_PENDING then
                TP_RETRY_PENDING = true
                windower.send_command('wait 1; gs c tp_retry')
            end
        end
    elseif command == 'tp_retry' then
        -- Back to TP after songs, but only when you are done
        -- singing: still Engaged, not in the middle of another
        -- song, and SONG_RETURN_DELAY seconds have passed since
        -- the last song finished. If you are mid-song, or you
        -- just finished one, wait 1 second and check again
        -- instead of swapping your instrument off mid-song.
        -- Idle between pulls: does nothing, stays in song gear.
        if player.status == 'Engaged' then
            local mid_song = (midaction ~= nil and midaction())
            local too_soon = (os.time() - LAST_SONG_TIME) < SONG_RETURN_DELAY
            if not mid_song and not too_soon then
                TP_RETRY_PENDING = false
                equip(sets.TP)
            else
                windower.send_command('wait 1; gs c tp_retry')
            end
        else
            -- Not Engaged any more: stop the chain, so the
            -- next song can start a fresh one when needed.
            TP_RETRY_PENDING = false
        end
    elseif command == 'tp' then
        equip(sets.TP)
        windower.add_to_chat(207, 'BRD: TP gear equipped, range should be Linos.')
    elseif command == 'pull' then
        equip(ELEGY_SET)
        windower.add_to_chat(207, 'BRD: pull gear (Carnage Elegy set) equipped.')
    elseif command == 'marsyas' then
        equip({range = "Marsyas"})
        windower.add_to_chat(207, 'BRD: Marsyas equipped.')
    elseif command == 'honor' then
        equip({range = "Marsyas"})
        windower.send_command('wait 1; input /ma "Honor March" <me>')
    end
end
