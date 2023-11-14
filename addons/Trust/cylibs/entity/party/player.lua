local packets = require('packets')
local PartyMember = require('cylibs/entity/party_member')
local MobUpdateMessage = require('cylibs/messages/mob_update_message')
local ZoneMessage = require('cylibs/messages/zone_message')

local Player = setmetatable({}, {__index = PartyMember })
Player.__index = Player

-------
-- Default initializer for a Player.
-- @tparam number id Mob id
-- @treturn Player A player
function Player.new(id)
    local self = setmetatable(PartyMember.new(id), Player)
    self:set_zone_id(windower.ffxi.get_info().zone)
    return self
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Player:monitor()
    if not PartyMember.monitor(self) then
        return
    end
    self.action_events.outgoing = windower.register_event('outgoing chunk', function(id, original, _, _, _)
        -- Notify target changes
        if id == 0x015 then
            local p = packets.parse('outgoing', original)
            self:update_target(p['Target Index'])
            self:set_position(p['X'], p['Y'], p['Z'])
            self:set_zone_id(windower.ffxi.get_info().zone)
        elseif id == 0x05E then
            local p = packets.parse('outgoing', original)
            local zone_line = p['Zone Line']
            local zone_type = p['Type']
            self:set_zone_id(windower.ffxi.get_info().zone, zone_line, zone_type)
        end
    end)
    self.action_events.gain_buff = windower.register_event('gain buff', function(buff_id)
        local player_buff_ids = party_util.get_buffs(self:get_mob().id)
        self:update_debuffs(player_buff_ids)
        self:update_buffs(player_buff_ids)
    end)
    self.action_events.lose_buff = windower.register_event('lose buff', function(buff_id)
        local player_buff_ids = party_util.get_buffs(self:get_mob().id)
        self:update_debuffs(player_buff_ids)
        self:update_buffs(player_buff_ids)
    end)
end

-------
-- Sets the (x, y, z) coordinate of the mob.
-- @tparam number x X coordinate
-- @tparam number y Y coordinate
-- @tparam number z Z coordinate
function Player:set_position(x, y, z)
    PartyMember.set_position(self, x, y, z)

    IpcRelay.shared():send_message(MobUpdateMessage.new(self:get_name(), x, y, z))
end

-------
-- Sets the zone id. Always sets to value of windower.ffxi.get_info().zone regardless of input.
-- @tparam number zone_id Zone id (see res/zones.lua)
-- @tparam number zone_line (optional) Zone line
-- @tparam number zone_type (optional) Zone type
function Player:set_zone_id(zone_id, zone_line, zone_type)
    PartyMember.set_zone_id(self, windower.ffxi.get_info().zone, zone_line, zone_type)

    IpcRelay.shared():send_message(ZoneMessage.new(self:get_name(), self:get_zone_id(), zone_line, zone_type, self:get_position()[1], self:get_position()[2], self:get_position()[3]))
end

return Player

