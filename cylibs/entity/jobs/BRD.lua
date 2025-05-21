---------------------------
-- Job file for Bard.
-- @class module
-- @name Bard

local inventory_util = require('cylibs/util/inventory_util')
local Item = require('resources/resources').Item

local Job = require('cylibs/entity/jobs/job')
local Bard = setmetatable({}, {__index = Job })
Bard.__index = Bard

-------
-- Buff ids for all songs (see buffs.lua)
local all_song_buff_ids = L{
    195, 196, 197, 198, 199, 200, 201, 202, 203,
    204, 205, 206, 207, 208, 209, 210, 211, 212,
    213, 214, 215, 216, 217, 218, 219, 220, 221,
    222, 223
}

local equip_mods = {
    [18342] = {0.2},            -- 'Gjallarhorn',    -- 75
    [18577] = {0.2},            -- 'Gjallarhorn',    -- 80
    [18578] = {0.2},            -- 'Gjallarhorn',    -- 85
    [18579] = {0.3},            -- 'Gjallarhorn',    -- 90
    [18580] = {0.3},            -- 'Gjallarhorn',    -- 95
    [18572] = {0.4},            -- 'Gjallarhorn',    -- 99
    [18840] = {0.4},            -- 'Gjallarhorn',    -- 99-2
    [18575] = {0.25},           -- 'Daurdabla',      -- 90
    [18576] = {0.25},           -- 'Daurdabla',      -- 95
    [18571] = {0.3},            -- 'Daurdabla',      -- 99
    [18839] = {0.3},            -- 'Daurdabla',      -- 99-2
    [19000] = {0.1},            -- 'Carnwenhan',     -- 75
    [19069] = {0.2},            -- 'Carnwenhan',     -- 80
    [19089] = {0.3},            -- 'Carnwenhan',     -- 85
    [19621] = {0.4},            -- 'Carnwenhan',     -- 90
    [19719] = {0.4},            -- 'Carnwenhan',     -- 95
    [19828] = {0.5},            -- 'Carnwenhan',     -- 99
    [19957] = {0.5},            -- 'Carnwenhan',     -- 99-2
    [20561] = {0.5},            -- 'Carnwenhan',     -- 119
    [20562] = {0.5},            -- 'Carnwenhan',     -- 119-2
    [20586] = {0.5},            -- 'Carnwenhan',     -- 119-3
    [21398] = {0.5},            -- 'Marsyas',
    [21400] = {0.1},            -- 'Blurred Harp',
    [21401] = {0.2,Ballad=0.2}, -- 'Blurred Harp +1',
    [21405] = {0.2} ,           -- 'Eminent Flute',
    [21404] = {0.3},			-- 'Linos'			-- assumes +2 songs augment
    [20629] = {0.05},           -- 'Legato Dagger',
    [20599] = {0.05},           -- 'Kali',
    [27672] = {Paeon=0.1},      -- 'Brioso Roundlet',
    [27693] = {Paeon=0.1},      -- 'Brioso Roundlet +1',
    [23049] = {Paeon=0.1},      -- 'Brioso Roundlet +2',
    [23384] = {Paeon=0.1},      -- 'Brioso Roundlet +3',
    [28074] = {0.1},            -- 'Mdk. Shalwar +1',
    [25865] = {0.12},           -- 'Inyanga Shalwar',
    [25866] = {0.15},           -- 'Inyanga Shalwar +1',
    [25882] = {0.17},           -- 'Inyanga Shalwar +2',
    [28232] = {0.1},            -- 'Brioso Slippers',
    [28253] = {0.11},           -- 'Brioso Slippers +1',
    [23317] = {0.13},           -- 'Brioso Slippers +2',
    [23652] = {0.15},           -- 'Brioso Slippers +3',
    [11073] = {Madrigal=0.1},   -- 'Aoidos\' Calot +2',
    [11093] = {0.1,Minuet=0.1}, -- 'Aoidos\' Hngrln. +2',
    [11113] = {March=0.1},      -- 'Ad. Mnchtte. +2',
    [11133] = {Ballad=0.1},     -- 'Aoidos\' Rhing. +2',
    [11153] = {Scherzo=0.1},    -- 'Aoidos\' Cothrn. +2',
    [11618] = {0.1},            -- 'Aoidos\' Matinee',
    [26031] = {0.1},            -- 'Brioso Whistle',
    [26032] = {0.2},            -- 'Moonbow Whistle',
    [26033] = {0.3},            -- 'Mnbw. Whistle +1',
    [26758] = {Madrigal=0.1},   -- 'Fili Calot',
    [26759] = {Madrigal=0.1},   -- 'Fili Calot +1',
    [23094] = {Madrigal=0.1},   -- 'Fili Calot +2',
    [23429] = {Madrigal=0.1},   -- 'Fili Calot +3',
    [26916] = {0.11,Minuet=0.1},-- 'Fili Hongreline',
    [26917] = {0.12,Minuet=0.1},-- 'Fili Hongreline +1',
    [23161] = {0.13,Minuet=0.1},-- 'Fili Hongreline +2',
    [23496] = {0.14,Minuet=0.1},-- 'Fili Hongreline +3',
    [27070] = {March=0.1},      -- 'Fili Manchettes',
    [27071] = {March=0.1},      -- 'Fili Manchettes +1',
    [23228] = {March=0.1},      -- 'Fili Manchettes +2',
    [23563] = {March=0.1},      -- 'Fili Manchettes +3',
    [27255] = {Ballad=0.1},     -- 'Fili Rhingrave',
    [27256] = {Ballad=0.1},     -- 'Fili Rhingrave +1',
    [23295] = {Ballad=0.1},     -- 'Fili Rhingrave +2',
    [23630] = {Ballad=0.1},     -- 'Fili Rhingrave +3',
    [27429] = {Scherzo=0.1},    -- 'Fili Cothurnes',
    [27430] = {Scherzo=0.1},    -- 'Fili Cothurnes +1',
    [23362] = {Scherzo=0.1},    -- 'Fili Cothurnes +2',
    [23697] = {Scherzo=0.1},    -- 'Fili Cothurnes +3',
    [26255] = {Madrigal=0.1,Prelude=0.1}, -- 'Intarabus\'s Cape',
    [25561] = {Etude=0.1},      -- 'Mousai Turban',
    [25562] = {Etude=0.2},      -- 'Mousai Turban +1',
    [25988] = {Carol=0.1},      -- 'Mousai Gages',
    [25989] = {Carol=0.2},      -- 'Mousai Gages +1',
    [25901] = {Minne=0.1},      -- 'Mousai Seraweels',
    [25902] = {Minne=0.2},      -- 'Mousai Seraweels +1',
    [25968] = {Mambo=0.1},      -- 'Mousai Crackows',
    [25969] = {Mambo=0.2},      -- 'Mousai Crackows +1',
}

-------
-- Default initializer for a new Bard.
-- @tparam T trust_settings Trust settings
-- @treturn BRD A Bard
function Bard.new(trust_settings)
    local self = setmetatable(Job.new('BRD', L{ 'Honor March', 'Aria of Passion', 'Dispelga' }), Bard)
    self:set_trust_settings(trust_settings)

    local jp = windower.ffxi.get_player().job_points.brd

    self.jp_mods = {}
    self.jp_mods.clarion = jp.clarion_call_effect * 2
    self.jp_mods.tenuto = jp.tenuto_effect * 2
    self.jp_mods.marcato = jp.marcato_effect
    self.jp_mods.mult = jp.jp_spent >= 1200

    return self
end

-------
-- Returns whether the player has nitro active.
-- @treturn Boolean True if nitro is active
function Bard:is_nitro_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(347) and player_buff_ids:contains(player_buff_ids:contains(348))
end

-------
-- Returns whether the player has Nightingale active.
-- @treturn Boolean True if Nightingale is active
function Bard:is_nightingale_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(347)
end

-------
-- Returns whether the player has Troubadour active.
-- @treturn Boolean True if Troubadour is active
function Bard:is_troubadour_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(348)
end

-------
-- Returns whether nitro is ready to use.
-- @treturn Boolean True if nitro is ready to use
function Bard:is_nitro_ready()
    return not self:is_nitro_active() and job_util.can_use_job_ability("Nightingale")
            and job_util.can_use_job_ability("Troubadour")
end

-------
-- Returns whether a buff is a bard song buff.
-- @tparam number buff_id Buff ids (see buffs.lua)
-- @treturn Boolean True if the buff id is for a bard song
function Bard:is_bard_song_buff(buff_id)
    return buff_id and all_song_buff_ids:contains(buff_id)
end

-------
-- Returns whether a spell is a bard song.
-- @tparam number spell_id Spell ids (see spells.lua)
-- @treturn Boolean True if the spell id is for a bard song
function Bard:is_bard_song(spell_id)
    local spell = res.spells[spell_id]
    return spell and self:is_bard_song_buff(spell.status)
end

-------
-- Returns whether clarion call is active.
-- @treturn Boolean True if clarion call is active
function Bard:is_clarion_call_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(buff_util.buff_id('Clarion Call'))
end

function Bard:is_soul_voice_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(buff_util.buff_id('Soul Voice'))
end

function Bard:is_marcato_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(buff_util.buff_id('Marcato'))
end

function Bard:is_tenuto_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(buff_util.buff_id('Tenuto'))
end

-------
-- Returns whether clarion call is ready to use.
-- @treturn Boolean True if clarion call is ready to use
function Bard:is_clarion_call_ready()
    return not self:is_clarion_call_active() and job_util.can_use_job_ability("Clarion Call")
end

-------
-- Returns the maximum number of songs that the player can have active.
-- @tparam boolean include_clarion_call (optional) Whether to take Clarion Call into account. If Clarion Call is active this will be set to true
-- @tparam number current_num_bard_songs (optional) The number of song buffs currently active
-- @treturn number Number of songs
function Bard:get_max_num_songs(include_clarion_call, current_num_bard_songs)
    local max_num_songs = self.max_num_songs
    if not self.gear_swap_enabled or self:getLevel() < 99 then
        max_num_songs = 2
    end
    local current_num_bard_songs = current_num_bard_songs or self:get_song_buff_ids():length()
    local num_songs = math.min(math.max(current_num_bard_songs, max_num_songs), max_num_songs + 1)
    if include_clarion_call or self:is_clarion_call_active() then
        num_songs = math.max(num_songs, max_num_songs + 1)
    end
    return num_songs
end

-------
-- Returns the buff ids for songs the player currently has.
-- @tparam list buff_ids (optional) Buff ids (see res/buffs.lua)
-- @treturn list List of song buff ids
function Bard:get_song_buff_ids(buff_ids)
    local buff_ids = buff_ids or L(windower.ffxi.get_player().buffs)
    return buff_ids:filter(function(buff_id)
        return self:is_bard_song_buff(buff_id)
    end)
end

-------
-- Returns the duration modifier for the given song, taking into account buffs, instruments and gear.
-- @tparam number song_name (optional) Name of the song (see res/spells.lua)
-- @treturn number Duration modifier of song
function Bard:get_song_duration_modifier(song_name)
    local modifier = 1.0
    if self:is_troubadour_active() then
        modifier = modifier * 2.0
    end
    return modifier
end

function Bard:get_song_duration(song_name, buffs)
    local mult = self.jp_mods.mult and 1.05 or 1

    local mod_item_ids = L{}

    local equipment_ids = inventory_util.get_equipment_ids()
    for item_id in equipment_ids:it() do
        local mod = equip_mods[item_id]
        if mod then
            for k,v in pairs(mod) do
                if k == 1 then
                    mult = mult + v
                    mod_item_ids:append(item_id)
                elseif string.find(song_name, k) then
                    mult = mult + v
                    mod_item_ids:append(item_id)
                end
            end
        end
    end

    local dur = 120
    if self:is_troubadour_active() then mult = mult*2 end
    if song_name == "Sentinel's Scherzo" then
        if self:is_soul_voice_active() then
            mult = mult * 2
        elseif self:is_marcato_active() then -- this might wear off
            mult = mult * 1.5
        end
    end
    dur = math.floor(mult * dur)

    if self:is_marcato_active() then dur = dur + self.jp_mods.marcato end
    if self:is_tenuto_active() then dur = dur + self.jp_mods.tenuto end
    if self:is_clarion_call_active() then dur = dur + self.jp_mods.clarion end

    return dur
end

-------
-- Returns the delay between songs, taking into account whether troubadour is active.
-- @treturn number Duration of song
function Bard:get_song_delay()
    local song_delay = self.song_delay
    if self:is_nightingale_active() then
        song_delay = math.max(song_delay * 0.5, 2)
    end
    return song_delay
end

-------
-- Returns the item ids of all instruments which grant 1 or more
-- additional song effects.
-- @treturn list List of item ids (see res/items.lua)
function Bard:get_extra_song_instrument_ids()
    return S{
        18571, -- Daurdabla
        18574, -- Daurdabla
        18575, -- Daurdabla
        18576, -- Daurdabla
        21407, -- Terpander
        22304, -- Loughnashade
        22305, -- Loughnashade
        22306, -- Loughnashade
        22307, -- Loughnashade
        22249, -- Miracle Cheer
    }
end

function Bard:validate_songs(song_names, dummy_song_names)
    if S(song_names):length() ~= 5 then
        return false, "You must pick 5 songs."
    end
    local buffsForSongs = S(song_names:map(function(song_name)
        return buff_util.buff_for_spell(spell_util.spell_id(song_name)).id
    end))
    local buffsForDummySongs = S(dummy_song_names:map(function(song_name)
        return buff_util.buff_for_spell(spell_util.spell_id(song_name)).id
    end))
    if set.intersection(buffsForDummySongs, buffsForSongs):length() > 0 then
        return false, "Dummy songs cannot give the same status effect as real songs."
    end
    return true, nil
end

function Bard:get_extra_song_items()
    return L{ 'Daurdabla', 'Blurred Harp', 'Blurred Harp +1', 'Terpander', 'Miracle Cheer' }
end

function Bard:get_extra_songs(item_name)
    local item_to_num_songs = {
        ['Daurdabla'] = 4,
        ['Loughnashade'] = 4,
        ['Terpander'] = 3,
        ['Blurred Harp'] = 3,
        ['Blurred Harp +1'] = 3,
        ['Miracle Cheer'] = 3,
    }
    return item_to_num_songs[item_name] or 2
end

-------
-- Updates the songs settings based on trust settings.
-- @tparam table Trust settings
function Bard:set_trust_settings(trust_settings)
    self.max_num_songs = trust_settings.SongSettings.NumSongs or 4
    self.song_duration = trust_settings.SongSettings.SongDuration or 240
    self.song_delay = trust_settings.SongSettings.SongDelay or 6
    self.gear_swap_enabled = trust_settings.GearSwapSettings.Enabled

    local max_num_songs = 2
    for item_name in self:get_extra_song_items():it() do
        local items = Item:where({ en = item_name }, L{ 'id' }, true)
        for item in items:it() do
            if inventory_util.get_item_count(item.id, true) > 0 then
                max_num_songs = math.max(max_num_songs, self:get_extra_songs(item_name))
            end
        end
    end
    self.max_num_songs = max_num_songs
end

return Bard