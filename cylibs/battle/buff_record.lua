---------------------------
-- Wrapper around a buff record.
-- @class module
-- @name BuffRecord

local BuffRecord = {}
BuffRecord.__index = BuffRecord
BuffRecord.__eq = BuffRecord.equals
BuffRecord.__tostring = BuffRecord.tostring
BuffRecord.__class = "BuffRecord"

-------
-- Default initializer for a new buff record.
-- @tparam number buff_id Buff id (see spells.lua)
-- @tparam number buff_duration Buff duration in seconds
-- @treturn BuffRecord A buff record
function BuffRecord.new(buff_id, buff_duration)
    local self = setmetatable({
        buff_id = buff_id;
        buff_duration = buff_duration;
        expire_time = os.time() + buff_duration
    }, BuffRecord)
    return self
end

-------
-- Returns whether a buff is expired.
-- @treturn Boolean True if the buff is expired
function BuffRecord:is_expired()
    return os.time() > self.expire_time
end

-------
-- Returns the expiration time.
-- @treturn number Expiration time
function BuffRecord:get_expire_time()
    return self.expire_time
end

-------
-- Returns the time remaining.
-- @treturn number Time remaining in seconds
function BuffRecord:get_time_remaining()
    return math.max(self:get_expire_time() - os.time(), 0)
end

-------
-- Sets the expiration time.
-- @tparam number expire_time Expiration time
function BuffRecord:set_expire_time(expire_time)
    self.expire_time = expire_time
end

-------
-- Returns the buff id for the buff.
-- @treturn number Buff id (see buffs.lua)
function BuffRecord:get_buff_id()
    return self.buff_id
end

-------
-- Returns whether two buff records are equal.
-- @tparam BuffRecord other_buff Other buff record
-- @treturn boolean True if the buff records are equal
function BuffRecord:equals(other_buff)
    return self:get_buff_id() == other_buff:get_buff_id()
        and self:get_expire_time() == other_buff:get_expire_time()
end

-------
-- Returns a string representation of this record.
-- @treturn string String representation of this record
function BuffRecord:tostring()
    return res.buffs[self:get_buff_id()].en
end

return BuffRecord