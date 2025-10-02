local json = require('cylibs/util/json')
local socket = require("socket")

require('queues')

local SyncService = {}
SyncService.__index = SyncService

function SyncService.new(remote_port)
    local self = setmetatable({}, SyncService)

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
        return 5
    end
end

function SyncService:enqueue(payload)
    self.queue:push(payload)
end

function SyncService:send_ping()
    local payload = {
        type = "ping",
        id = tostring(os.time()), -- or use a guid generator if you have one
        target = tostring(windower.ffxi.get_player().name),       -- optional, whatever your channel expects
        payload = {
            sent_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            message = message or "hello from lua",
        }
    }
    self.queue:push(payload)
end

function SyncService:send_info()
    --[[for payload in self.queue:it() do
        local data = json.encode(payload)
        if data then
            local udp = assert(socket.udp())

            udp:setpeername(self.ip_address, self.remote_port)
            udp:settimeout(0)


            local success = udp:send(data)
            if not success then
                error(string.format("Failed to connect to %s:%d", self.ip_address, self.port))
            end
            udp:close()
        end
    end
    self.queue:clear()]]
    for payload in self.queue:it() do
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
    --[[local ok, error = pcall(function()
        local data, error = self.receiver:receive()
        if data then
            local json = json.decode(data)
            print(T(json):keyset())
        else
            --if error then
            --    print('error receiving', error)
            --end
        end
    end)]]


    local data
    repeat
        local ok, err = pcall(function()
            data, from_ip, from_port = self.sock:receivefrom()
            if data then
                -- handle your incoming data here
                print(string.format("[sync] recv %dB from %s:%d", #data, from_ip or "?", from_port or -1))
            end
        end)
        if not ok then
            print('[receive_info] Error:', err)
            return
        end
    until not data
end

return SyncService