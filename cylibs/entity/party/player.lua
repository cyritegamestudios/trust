local inventory_util = require('cylibs/util/inventory_util')
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
    self:set_main_weapon_id(inventory_util.get_main_weapon_id())
    return self
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Player:monitor()
    if not PartyMember.monitor(self) then
        return
    end

    self.dispose_bag:add(WindowerEvents.Equipment.MainWeaponChanged:addAction(function(mob_id, main_weapon_id)
        if mob_id == self:get_id() then
            self:set_main_weapon_id(main_weapon_id)
        end
    end))
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

-------
-- Returns the item id of the main weapon equipped.
-- @tparam number Item id of main weapon equipped (see res/items.lua)
function Player:get_main_weapon_id()
    return self.main_weapon_id
end

-------
-- Sets the main weapon item id.
-- @tparam number main_weapon_id Item id (see res/items.lua)
function Player:set_main_weapon_id(main_weapon_id)
    if self.main_weapon_id == main_weapon_id then
        return
    end
    self.main_weapon_id = main_weapon_id
    self:on_equipment_change():trigger(self)
end

return Player

