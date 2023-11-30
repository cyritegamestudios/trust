local Event = require('cylibs/events/Luvent')

local IpcConnection = {}
IpcConnection.__index = IpcConnection

function IpcConnection.new(target_name)
    local self = setmetatable({
    }, IpcConnection)

    self.target_name = target_name

    return self
end

function IpcConnection:destroy()
end

-------
-- Returns the last heartbeat time.
-- @treturn number Last heartbeat time
function IpcConnection:get_last_message_sent_time()
    return self.heartbeat_time
end

-------
-- Sets the heartbeat time.
-- @tparam number time_in_sec Time
function IpcConnection:set_last_message_sent_time(time_in_sec)
    self.heartbeat_time = time_in_sec
end

return IpcConnection



