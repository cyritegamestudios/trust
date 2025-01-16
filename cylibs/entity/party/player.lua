local EquipmentChangedMessage = require('cylibs/messages/equipment_changed_message')
local Event = require('cylibs/events/Luvent')
local inventory_util = require('cylibs/util/inventory_util')
local PartyMember = require('cylibs/entity/party_member')
local Weapon = require('cylibs/battle/weapons/weapon')

local Player = setmetatable({}, {__index = PartyMember })
Player.__index = Player
Player.__class = "Player"

-- Event called when a player's level changes.
function PartyMember:on_level_change()
    return self.level_change
end

-------
-- Default initializer for a Player.
-- @tparam number id Mob id
-- @treturn Player A player
function Player.new(id)
    local self = setmetatable(PartyMember.new(id, windower.ffxi.get_player().name), Player)

    self:set_zone_id(windower.ffxi.get_info().zone)
    local main_weapon_id = inventory_util.get_main_weapon_id()
    if main_weapon_id and main_weapon_id ~= 0 then
        self:set_main_weapon_id(main_weapon_id)
    end
    local ranged_weapon_id = inventory_util.get_ranged_weapon_id()
    if ranged_weapon_id and ranged_weapon_id ~= 0 then
        self:set_ranged_weapon_id(ranged_weapon_id)
    end

    self:set_target_index(windower.ffxi.get_player().target_index)

    self.events = {}
    self.level_change = Event.newEvent()

    return self
end

function Player:destroy()
    PartyMember.destroy(self)

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end

    self.level_change:removeAllActions()
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
    self.dispose_bag:add(WindowerEvents.Equipment.RangedWeaponChanged:addAction(function(mob_id, ranged_weapon_id)
        if mob_id == self:get_id() then
            self:set_ranged_weapon_id(ranged_weapon_id)
        end
    end))
    self.dispose_bag:add(WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        if owner_id == self:get_id() then
            self:set_pet(pet_id, pet_name)
        end
    end), WindowerEvents.PetUpdate)

    self.dispose_bag:add(IpcRelay.shared():on_connected():addAction(function(_)
        IpcRelay.shared():send_message(EquipmentChangedMessage.new(self:get_id(), self:get_main_weapon_id(), self:get_ranged_weapon_id()))
    end))

    self.events.level_up = windower.register_event('level up', function(new_level)
        self:on_level_change():trigger(self, new_level)
    end)

    self.events.level_down = windower.register_event('level down', function(new_level)
        self:on_level_change():trigger(self, new_level)
    end)
end

-------
-- Sets the target index of the player.
-- @tparam number target_index Target index
function Player:set_target_index(_)
    local target = windower.ffxi.get_mob_by_target('t')
    PartyMember.set_target_index(self, target and target.index or windower.ffxi.get_player().target_index)
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
-- Returns the localized status of the player.
-- @treturn string Status of the player (see res/statuses.lua)
function Player:get_status()
    local mob = self:get_mob()
    if mob then
        return res.statuses[mob.status].en
    end
    return 'Idle'
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
    self:update_combat_skills()

    self:on_equipment_change():trigger(self)
end

-------
-- Returns the item id of the ranged weapon equipped.
-- @tparam number Item id of ranged weapon equipped (see res/items.lua)
function Player:get_ranged_weapon_id()
    return self.ranged_weapon_id
end

-------
-- Sets the ranged weapon item id.
-- @tparam number ranged_weapon_id Item id (see res/items.lua)
function Player:set_ranged_weapon_id(ranged_weapon_id)
    if self.ranged_weapon_id == ranged_weapon_id then
        return
    end
    self.ranged_weapon_id = ranged_weapon_id
    self:update_combat_skills()

    self:on_equipment_change():trigger(self)
end

-------
-- Returns the item id of the ranged weapon equipped.
-- @tparam number Item id of ranged weapon equipped (see res/items.lua)
function Player:get_combat_skill_ids()
    return self.combat_skill_ids
end

-------
-- Sets the ranged weapon item id.
-- @tparam number ranged_weapon_id Item id (see res/items.lua)
function Player:update_combat_skills()
    local combat_skill_ids = L{ self:get_main_weapon_id(), self:get_ranged_weapon_id() }:compact_map():map(function(weapon_id)
        local weapon = Weapon.new(weapon_id)
        return weapon:get_combat_skill()
    end)
    if self.combat_skill_ids:equals(combat_skill_ids) then
        return
    end
    self.combat_skill_ids = combat_skill_ids

    self:on_combat_skills_change():trigger(self, self.combat_skill_ids)
end

-------
-- Returns the main job short (e.g. BLU, RDM, WAR)
-- @treturn string Main job short, or nil if unknown
function Player:get_main_job_short()
    return player.main_job_name_short
end

-------
-- Returns the sub job short (e.g. BLU, RDM, WAR)
-- @treturn string Sub job short, or nil if unknown
function Player:get_sub_job_short()
    return player.sub_job_name_short
end

return Player

