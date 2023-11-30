local PartyMember = require('cylibs/entity/party_member')

local Player = setmetatable({}, {__index = PartyMember })
Player.__index = Player
Player.__class = "Player"

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
end

-------
-- Sets the target index of the player.
-- @tparam number target_index Target index
function Player:set_target_index(_)
    PartyMember.set_target_index(self, windower.ffxi.get_player().target_index)
end

-------
-- Sets the zone id. Always sets to value of windower.ffxi.get_info().zone regardless of input.
-- @tparam number zone_id Zone id (see res/zones.lua)
-- @tparam number zone_line (optional) Zone line
-- @tparam number zone_type (optional) Zone type
function Player:set_zone_id(zone_id, zone_line, zone_type)
    PartyMember.set_zone_id(self, windower.ffxi.get_info().zone, zone_line, zone_type)
end

return Player

