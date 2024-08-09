---------------------------
-- Job file for Bard.
-- @class module
-- @name Bard

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

-------
-- Default initializer for a new Bard.
-- @tparam T trust_settings Trust settings
-- @treturn BRD A Bard
function Bard.new(trust_settings)
    local self = setmetatable(Job.new(), Bard)
    self.max_num_songs = trust_settings.SongSettings.NumSongs or 4
    self.song_duration = trust_settings.SongSettings.SongDuration or 240
    self.song_delay = trust_settings.SongSettings.SongDelay or 6
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
    return all_song_buff_ids:contains(buff_id)
end

-------
-- Returns whether clarion call is active.
-- @treturn Boolean True if clarion call is active
function Bard:is_clarion_call_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(buff_util.buff_id('Clarion Call'))
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
    local current_num_bard_songs = current_num_bard_songs or self:get_song_buff_ids():length()
    local num_songs = math.min(math.max(current_num_bard_songs, self.max_num_songs), self.max_num_songs + 1)
    if include_clarion_call or self:is_clarion_call_active() then
        num_songs = math.max(num_songs, self.max_num_songs + 1)
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
-- Returns the maximum duration of a song, taking into account whether troubadour is active.
-- @tparam number song_name (optional) Name of the song (see res/spells.lua)
-- @treturn number Duration of song
function Bard:get_song_duration(song_name)
    local modifier = 1.0
    if song_name then
        if song_name == 'Honor March' then
            modifier = 1.0
        end
    end
    local base_song_duration = self.song_duration * modifier
    if self:is_troubadour_active() then
        return base_song_duration * 2
    end
    return base_song_duration
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
    }
end

return Bard