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
-- @treturn BRD A Bard
function Bard.new()
    local self = setmetatable(Job.new(), Bard)
    return self
end

-------
-- Returns the number of songs the player has active out of a given list of songs.
-- @tparam List Buff ids. If nil, uses buff ids for all songs. (see buffs.lua)
-- @treturn number Number of songs active
function Bard:get_num_songs(buff_ids)
    buff_ids = buff_ids or all_song_buff_ids
    local count = 0
    for buff_id in buff_ids:it() do
        if buff_util.is_buff_active(buff_id) then
            count = count + 1
        end
    end
    return count
end

-------
-- Returns whether the player has at least one of the given songs active.
-- @tparam List Buff ids (see buffs.lua)
-- @tparam List Buff ids for player's current buffs (see buffs.lua)
-- @treturn Boolean True if at least one of the given songs is active
function Bard:has_any_song(buff_ids, player_buff_ids)
    player_buff_ids = player_buff_ids or L(windower.ffxi.get_player().buffs)
    for buff_id in buff_ids:it() do
        if buff_util.is_buff_active(buff_id, player_buff_ids) then
            return true
        end
    end
    return false
end

-------
-- Returns whether the player has the given song effect active.
-- @tparam Spell Song
-- @tparam List Buff ids for player's current buffs (see buffs.lua)
-- @treturn Boolean True if the given song effect is active
function Bard:has_song(song, player_buff_ids)
    player_buff_ids = player_buff_ids or L(windower.ffxi.get_player().buffs)
    local buff = buff_util.buff_for_spell(song:get_spell().id)
    if buff and buff_util.is_buff_active(buff.id, player_buff_ids) then
        return true
    end
    return false
end

-------
-- Returns whether the player has all of the given songs active.
-- @tparam List Buff ids (see buffs.lua)
-- @tparam List Buff ids for player's current buffs (see buffs.lua)
-- @treturn Boolean True if all of the given songs are active
function Bard:has_all_songs(buff_ids, player_buff_ids)
    player_buff_ids = player_buff_ids or L(windower.ffxi.get_player().buffs)
    for buff_id in buff_ids:it() do
        if not buff_util.is_buff_active(buff_id, player_buff_ids) then
            return false
        end
    end
    return true
end

-------
-- Returns whether the player has nitro active.
-- @treturn Boolean True if nitro is active
function Bard:is_nitro_active()
    local player_buff_ids = L(windower.ffxi.get_player().buffs)
    return player_buff_ids:contains(L{347, 348})
end

-------
-- Returns whether nitro is ready to use.
-- @treturn Boolean True if nitro is ready to use
function Bard:is_nitro_ready()
    return not self:is_nitro_active() and job_util.can_use_job_ability("Nightingale")
            and job_util.can_use_job_ability("Troubadour")
end


return Bard