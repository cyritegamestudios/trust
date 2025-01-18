---------------------------
-- Represents a song set.
-- @class module
-- @name SongSet
local serializer_util = require('cylibs/util/serializer_util')

local SongSet = {}
SongSet.__index = SongSet
SongSet.__type = "SongSet"
SongSet.__class = "SongSet"

function SongSet.new(songs)
    local self = setmetatable({}, SongSet)
    self.songs = songs or L{}
    return self
end

function SongSet:getSpells()
    return self.songs
end

function SongSet:tostring()
    return "Songs: "..self.songs:tostring()
end

function SongSet:serialize()
    return "SongSet.new(" .. serializer_util.serialize_args(self.songs) .. ")"
end

return SongSet




