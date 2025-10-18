local json = require('cylibs/util/json')
local socket = require("socket")

require('queues')

local SyncService = {}
SyncService.__index = SyncService

function SyncService.new(remote_port)
    local self = setmetatable({}, SyncService)

    self.handlers = {}
    self.ip_address = "127.0.0.1"
    self.receiver = assert(socket.udp())
    self.receiver:setsockname(self.ip_address, 0)  -- bind to localhost on dynamic port
    self.receiver:settimeout(0)

    local _, receiver_port = self.receiver:getsockname()
    print(receiver_port, type(receiver_port))

    self.port = tonumber(receiver_port)
    self.remote_port = remote_port or 5000

    self.sock = assert(socket.udp())
    assert(self.sock:setsockname(self.ip_address, 0))   -- 0 = pick an available port
    self.sock:settimeout(0)

    local _, local_port = self.sock:getsockname()
    self.local_port = tonumber(local_port)
    print(string.format("[sync] bound to %s:%d", self.ip_address, self.local_port))

    self.connected       = false
    self.queue           = Q{}
    self.last_sync_time  = os.time()

    return self
end

function SyncService:connect()
    if self.initialized then
        return
    end
    self.initialized = true

    windower.register_event('prerender', function()
        if os.time() - self.last_sync_time < self:get_cooldown() then
            return
        end
        self.last_sync_time = os.time()

        self:send_info()
        self:receive_info()
    end)
end

function SyncService:set_connected(connected)
    if connected == self.connected then
        return
    end
    self.connected = connected

    if self.connected then
        addon_message(123, "Now connected")
    end
end

function SyncService:get_cooldown()
    if self.connected then
        return 1
    else
        return 1
    end
end

function SyncService:enqueue(message_type, payload)
    self.queue:push({ type = message_type, payload = payload })
end

function SyncService:flush_queue()
    self:send_info()
end

function SyncService:send_info()
    for message in self.queue:it() do
        print('sending message of type', message.type)
        local payload = {
            type = message.type,
            id = tostring(os.time()),
            user_name = tostring(windower.ffxi.get_player().name),
            user_id = windower.ffxi.get_player().id,
            sent_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            payload = message.payload,
        }
        local data = json.encode(payload)
        if data then
            -- reuse the same socket; keep your local port stable
            local ok, err = self.sock:sendto(data, self.ip_address, self.remote_port)
            if not ok then
                print(string.format("[sync] send error to %s:%d -> %s", self.ip_address, self.remote_port, tostring(err)))
            end
        end
    end
    self.queue:clear()
end

function SyncService:receive_info()
    local data
    repeat
        local ok, err = pcall(function()
            data, from_ip, from_port = self.sock:receivefrom()
            if data then
                local json = json.decode(data)
                if json["type"] then
                    for handler in (self.handlers[json["type"]] or L{}):it() do
                        handler(json["payload"] or {})
                    end
                end
                print(string.format("[sync] recv %dB from %s:%d", #data, from_ip or "?", from_port or -1))
            end
        end)
        if not ok then
            print('[receive_info] Error:', err)
            return
        end
    until not data
end

function SyncService:register_handler(type, handler)
    self.handlers[type] = self.handlers[type] or L{}

    local handlers = self.handlers[type]
    handlers:append(handler)
end

return SyncService