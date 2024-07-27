---------------------------
-- Wrapper around a song record.
-- @class module
-- @name SongRecord

local SongRecord = {}
SongRecord.__index = SongRecord
SongRecord.__eq = SongRecord.equals
SongRecord.__class = "SongRecord"

-------
-- Default initializer for a new song record.
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number song_duration Song duration in seconds
-- @treturn SongRecord A song record
function SongRecord.new(song_id, song_duration)
    local self = setmetatable({
        song_id = song_id;
        song_duration = song_duration;
        expire_time = os.time() + song_duration
    }, SongRecord)
    return self
end

-------
-- Returns whether a song is expired.
-- @treturn Boolean True if the song is expired
function SongRecord:is_expired()
    return os.time() > self.expire_time
end

-------
-- Returns the expiration time.
-- @treturn number Expiration time
function SongRecord:get_expire_time()
    return self.expire_time
end

-------
-- Returns the time remaining.
-- @treturn number Time remaining in seconds
function SongRecord:get_time_remaining()
    return math.max(self:get_expire_time() - os.time(), 0)
end

-------
-- Sets the expiration time.
-- @tparam number expire_time Expiration time
function SongRecord:set_expire_time(expire_time)
    self.expire_time = expire_time
end

-------
-- Sets the song duration.
-- @tparam number song_duration New song duration
function SongRecord:set_song_duration(song_duration)
    self.song_duration = song_duration
    self.expire_time = os.time() + self.song_duration
end

-------
-- Returns the song id.
-- @treturn number Song id (see spells.lua)
function SongRecord:get_song_id()
    return self.song_id
end

-------
-- Returns the buff id for the song.
-- @treturn number Buff id (see buffs.lua)
function SongRecord:get_buff_id()
    return res.spells:with('id', self:get_song_id()).status
end

-------
-- Returns the song id.
-- @treturn number Song id (see spells.lua)
function SongRecord:equals(other_song)
    return self:get_song_id() == other_song:get_song_id()
end

-------
-- Returns a string representation of this record.
-- @treturn string String representation of this record
function SongRecord:tostring()
    return res.spells:with('id', self:get_song_id()).en
end

return SongRecord