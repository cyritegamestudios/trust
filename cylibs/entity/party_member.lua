---------------------------
-- Wrapper class around a party member.
-- @class module
-- @name PartyMember

local BattleStatTracker = require('cylibs/battle/battle_stat_tracker')
local battle_util = require('cylibs/util/battle_util')
local buff_util = require('cylibs/util/buff_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local ffxi_util = require('cylibs/util/ffxi_util')
local party_util = require('cylibs/util/party_util')
local res = require('resources')
local Weapon = require('cylibs/battle/weapons/weapon')

local PartyMember = setmetatable({}, {__index = Entity })
PartyMember.__index = PartyMember
PartyMember.__class = "PartyMember"

-- Event called when the party member's target changes.
function PartyMember:on_target_change()
    return self.target_change
end

-- Event called when a party member gains a debuff.
function PartyMember:on_gain_debuff()
    return self.gain_debuff
end

-- Event called when a party member loses a debuff.
function PartyMember:on_lose_debuff()
    return self.lose_debuff
end

-- Event called when a party member gains a buff.
function PartyMember:on_gain_buff()
    return self.gain_buff
end

-- Event called when a party member loses a buff.
function PartyMember:on_lose_buff()
    return self.lose_buff
end

-- Event called when a party member's HP changes.
function PartyMember:on_hp_change()
    return self.hp_change
end

-- Event called when a party member is knocked out.
function PartyMember:on_ko()
    return self.ko
end

-- Event called when the party member's position changes.
function PartyMember:on_position_change()
    return self.position_change
end

-- Event called when the party member's zone changes. Only works when IpcMode is not set to Off.
function PartyMember:on_zone_change()
    return self.zone_change
end

-- Event called when the party member's equipment changes.
function PartyMember:on_equipment_change()
    return self.equipment_change
end

-- Event called when the party member's combat skills change.
function PartyMember:on_combat_skills_change()
    return self.combat_skills_change
end

-- Event called when the party member's pet changes.
function PartyMember:on_pet_change()
    return self.pet_change
end

-- Event called when a player's spell finishes casting.
function PartyMember:on_spell_finish()
    return self.spell_finish
end

-------
-- Default initializer for a PartyMember.
-- @tparam number id Mob id
-- @treturn PartyMember A party member
function PartyMember.new(id, name)
    local self = setmetatable(Entity.new(id), PartyMember)
    self.uuid = os.time()
    self.id = id
    self.name = name
    self.main_job_short = 'NON'
    self.sub_job_short = 'NON'
    self.hpp = 100
    self.hp = 0
    self.mpp = 0
    self.mp = 0
    self.tp = 0
    self.target_index = nil
    self.zone_id = nil
    self.action_events = {}
    self.debuff_ids = L{}
    self.buff_ids = L{}
    self.combat_skill_ids = S{}
    self.battle_stat_tracker = BattleStatTracker.new(id)
    self.is_monitoring = false
    self.last_zone_time = os.time()
    self.heartbeat_time = os.time()
    self.dispose_bag = DisposeBag.new()

    self.target_change = Event.newEvent()
    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()
    self.gain_buff = Event.newEvent()
    self.lose_buff = Event.newEvent()
    self.hp_change = Event.newEvent()
    self.ko = Event.newEvent()
    self.position_change = Event.newEvent()
    self.zone_change = Event.newEvent()
    self.equipment_change = Event.newEvent()
    self.combat_skills_change = Event.newEvent()
    self.pet_change = Event.newEvent()
    self.spell_finish = Event.newEvent()

    local party_member_info = party_util.get_party_member_info(id)
    if party_member_info then
        self.hp = party_member_info.hp or 0
        self.hpp = party_member_info.hpp or 100
        self.mp = party_member_info.mp or 0
        self.mpp = party_member_info.mpp or 100
        self.tp = party_member_info.tp or 0
        self.zone = party_member_info.zone
        self.name = party_member_info.name

        if party_member_info.mob then
            self.target_index = party_member_info.mob.target_index
            self:set_position(party_member_info.mob.x, party_member_info.mob.y, party_member_info.mob.z)
            self:set_zone_id(windower.ffxi.get_info().zone)
        end
    end

    self:set_buff_ids(party_util.get_buffs(self.id))
    self:set_debuff_ids(L(buff_util.debuffs_for_buff_ids(party_util.get_buffs(self.id))))

    self.dispose_bag:addAny(L{ self.battle_stat_tracker })

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function PartyMember:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.dispose_bag:destroy()

    self.target_change:removeAllActions()
    self.gain_debuff:removeAllActions()
    self.lose_debuff:removeAllActions()
    self.gain_buff:removeAllActions()
    self.lose_buff:removeAllActions()
    self.hp_change:removeAllActions()
    self.ko:removeAllActions()
    self.position_change:removeAllActions()
    self.zone_change:removeAllActions()
    self.equipment_change:removeAllActions()
    self.combat_skills_change:removeAllActions()
    self.pet_change:removeAllActions()
    self.spell_finish:removeAllActions()
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function PartyMember:monitor()
    if self.is_monitoring then
        return false
    end
    self.is_monitoring = true

    self.battle_stat_tracker:monitor()

    self.dispose_bag:add(WindowerEvents.CharacterUpdate:addAction(function(mob_id, name, hp, hpp, mp, mpp, tp, main_job_id, sub_job_id)
        if self:get_id() == mob_id then
            self.name = name
            self.main_job_short = main_job_id and res.jobs[main_job_id]['ens'] or 'NON'
            self.sub_job_short = sub_job_id and res.jobs[sub_job_id]['ens'] or 'NON'

            self:set_hp(hp)
            self:set_hpp(hpp)
            self:set_mp(mp)
            self:set_mpp(mpp)
            self:set_tp(tp)
        end
    end), WindowerEvents.CharacterUpdate)

    self.dispose_bag:add(WindowerEvents.PositionChanged:addAction(function(mob_id, x, y, z)
        if self:get_id() == mob_id then
            self:set_position(x, y, z)
        end
    end), WindowerEvents.PositionChanged)

    self.dispose_bag:add(WindowerEvents.TargetIndexChanged:addAction(function(mob_id, target_index)
        if self:get_id() == mob_id then
            self:set_target_index(target_index)
        end
    end), WindowerEvents.TargetIndexChanged)

    self.dispose_bag:add(WindowerEvents.Equipment.MainWeaponChanged:addAction(function(mob_id, main_weapon_id)
        if self:get_id() == mob_id then
            self:set_main_weapon_id(main_weapon_id)
        end
    end), WindowerEvents.Equipment.MainWeaponChanged)

    self.dispose_bag:add(WindowerEvents.Equipment.RangedWeaponChanged:addAction(function(mob_id, ranged_weapon_id)
        if self:get_id() == mob_id then
            self:set_ranged_weapon_id(ranged_weapon_id)
        end
    end), WindowerEvents.Equipment.RangedWeaponChanged)

    self.dispose_bag:add(WindowerEvents.BuffsChanged:addAction(function(mob_id, buff_ids)
        if self:get_id() == mob_id then
            self:set_buff_ids(buff_ids)
        end
    end), WindowerEvents.BuffsChanged)

    self.dispose_bag:add(WindowerEvents.DebuffsChanged:addAction(function(mob_id, debuff_ids)
        if self:get_id() == mob_id then
            self:set_debuff_ids(debuff_ids)
        end
    end), WindowerEvents.BuffsChanged)

    self.dispose_bag:add(WindowerEvents.ZoneUpdate:addAction(function(mob_id, zone_id)
        if self:get_id() == mob_id then
            self:set_zone_id(zone_id)
        end
    end), WindowerEvents.ZoneUpdate)

    self.dispose_bag:add(WindowerEvents.ZoneRequest:addAction(function(mob_id, current_zone_id, zone_line, zone_type)
        if mob_id == self:get_id() then
            self:set_zone_id(current_zone_id, zone_line, zone_type)
        end
    end), WindowerEvents.ZoneRequest)

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if action.actor_id ~= self:get_id() then return end

        if action.category == 4 then
            self:on_spell_finish():trigger(self, action.param, action.targets)
        end
    end), WindowerEvents.Action)

    self.dispose_bag:add(self:on_target_change():addAction(function(_, _)
        self.battle_stat_tracker:reset()
    end), self:on_target_change())

    return true
end

function PartyMember:update_target(target_index)
    self:set_target_index(target_index)
end

-------
-- Filters a list of buffs and updates the player's cached list of debuffs.
-- @tparam list List of buff ids (see buffs.lua)
function PartyMember:set_debuff_ids(debuff_ids)
    if debuff_ids == nil then
        return
    end

    local delta = list.diff(debuff_ids, self.debuff_ids)
    for debuff_id in delta:it() do
        if debuff_ids:contains(debuff_id) then
            self:on_gain_debuff():trigger(self, debuff_id)
        else
            self:on_lose_debuff():trigger(self, debuff_id)
        end
    end
    self.debuff_ids = debuff_ids
end

-------
-- Returns a list of the party member's debuff ids.
-- @treturn List of debuff ids (see buffs.lua)
function PartyMember:get_debuff_ids()
    return self.debuff_ids
end

-------
-- Returns a list of the party member's debuffs.
-- @treturn List of localized debuff names (see buffs.lua)
function PartyMember:get_debuffs()
    return L(self.debuff_ids:map(function(debuff_id)
        return res.buffs:with('id', debuff_id).enl
    end))
end

-------
-- Returns true if the party member has the given debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn boolean True if the party member has the given debuff, false otherwise
function PartyMember:has_debuff(debuff_id)
    return self.debuff_ids:contains(debuff_id)
end

-------
-- Filters a list of buffs and updates the player's cached list of buffs.
-- @tparam list List of buff ids (see buffs.lua)
function PartyMember:set_buff_ids(buff_ids)
    if buff_ids == nil then
        return
    end
    local old_buff_ids = self.buff_ids

    self.buff_ids = buff_ids

    local delta = list.diff(old_buff_ids, buff_ids)
    for buff_id in delta:it() do
        if buff_ids:contains(buff_id) then
            self:on_gain_buff():trigger(self, buff_id)
        else
            self:on_lose_buff():trigger(self, buff_id)
        end
    end
    self.buff_ids = buff_ids
end

-------
-- Returns a list of the party member's buff ids.
-- @treturn List of buff ids (see buffs.lua)
function PartyMember:get_buff_ids()
    return self.buff_ids
end

-------
-- Returns a list of the party member's buffs.
-- @treturn List of localized buff names (see buffs.lua)
function PartyMember:get_buffs()
    return L(self.buff_ids:map(function(buff_id)
        return res.buffs:with('id', buff_id).enl
    end))
end

-------
-- Returns true if the party member has the given buff active.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @treturn boolean True if the buff is active, false otherwise
function PartyMember:has_buff(buff_id)
    return self.buff_ids:contains(buff_id)
end

-------
-- Returns the main job short (e.g. BLU, RDM, WAR)
-- @treturn string Main job short, or nil if unknown
function PartyMember:get_main_job_short()
    return self.main_job_short
end

-------
-- Returns the sub job short (e.g. BLU, RDM, WAR)
-- @treturn string Sub job short, or nil if unknown
function PartyMember:get_sub_job_short()
    return self.sub_job_short
end

-------
-- Sets the party member's current hit point percentage.
-- @tparam number Hit point percentage
function PartyMember:set_hpp(hpp)
    hpp = hpp or 100
    if self.hpp == hpp then
        return
    end
    self.hpp = hpp
    if self.hpp > 0 then
        self:on_hp_change():trigger(self, hpp, self:get_hp() / (hpp / 100.0))
    else
        self:on_ko():trigger(self)
    end
end

-------
-- Returns the player's current hit point percentage.
-- @treturn number Hit point percentage
function PartyMember:get_hpp()
    return self.hpp
end

-------
-- Sets the party member's current hit points.
-- @tparam number Hit points
function PartyMember:set_hp(hp)
    hp = hp or 0
    if self.hp == hp then
        return
    end
    self.hp = hp
    if self.hp > 0 then
        self:on_hp_change():trigger(self, self:get_hpp(), hp / (self:get_hpp() / 100.0))
    else
        self:on_ko():trigger(self)
    end
end

-------
-- Returns the player's current hit points.
-- @treturn number Hit points
function PartyMember:get_hp()
    return self.hp
end

-------
-- Returns the player's maximum hit points.
-- @treturn number Maximum hit points
function PartyMember:get_max_hp()
    return self.hp / (self.hpp / 100.0)
end

-------
-- Sets the party member's current mana point percentage.
-- @tparam number Mana point percentage
function PartyMember:set_mpp(mpp)
    mpp = mpp or 100
    if self.mpp == mpp then
        return
    end
    self.mpp = mpp
end

-------
-- Returns the player's current mana point percentage.
-- @treturn number Mana point percentage
function PartyMember:get_mpp()
    return self.mpp
end

-------
-- Sets the party member's current mana points.
-- @tparam number Mana points
function PartyMember:set_mp(mp)
    mp = mp or 0
    if self.mp == mp then
        return
    end
    self.mp = mp
end

-------
-- Returns the player's current mana points.
-- @treturn number Mana points
function PartyMember:get_mp()
    return self.mp
end

-------
-- Sets the party member's current tactical points.
-- @tparam number Tactical points
function PartyMember:set_tp(tp)
    tp = tp or 0
    if self.tp == tp then
        return
    end
    self.tp = tp
end

-------
-- Returns the player's current tactical points.
-- @treturn number Tactical points
function PartyMember:get_tp()
    return self.tp
end

-------
-- Returns whether the party member is alive.
-- @treturn Boolean True if the party member is alive, and false otherwise.
function PartyMember:is_alive()
    return self.hpp > 0
end

-------
-- Returns whether this party member is a trust.
-- @treturn Boolean True if the party member is a trust, and false otherwise
function PartyMember:is_trust()
    return false
end

-------
-- Returns whether this party member is the player.
-- @treturn Boolean True if the party member is the player, and false otherwise
function PartyMember:is_player()
    return self:get_id() == windower.ffxi.get_player().id
end

-------
-- Sets the target index for the party member.
-- @tparam number Index of the current target, or nil if none.
function PartyMember:set_target_index(target_index)
    if self.target_index ~= target_index then
        local old_target_index = self.target_index
        if target_index and target_index ~= 0 and battle_util.is_valid_monster_target(ffxi_util.mob_id_for_index(target_index)) then
            local target = windower.ffxi.get_mob_by_index(target_index)
            if target then
                --if target and party_util.party_claimed(target.id) then
                self.target_index = target.index
                if old_target_index ~= target.index then
                    self:on_target_change():trigger(self, self.target_index, old_target_index)
                end
            end
        else
            self.target_index = nil
            if old_target_index ~= self.target_index then
                self:on_target_change():trigger(self, self.target_index, old_target_index)
            end
        end
    end
end

-------
-- Returns the index of the current target.
-- @treturn number Index of the current target, or nil if none.
function PartyMember:get_target_index()
    return self.target_index
end

-------
-- Returns the localized status of the party member.
-- @treturn string Status of the party member (see res/statuses.lua)
function PartyMember:get_status()
    local mob = self:get_mob()
    if mob then
        return res.statuses[mob.status].en
    end
    return 'Idle'
end

-------
-- Sets the index for the party member's pet.
-- @tparam number Id of pet
-- @tparam string Name of pet
function PartyMember:set_pet(pet_id, pet_name)
    if self.pet_id == pet_id then
        return
    end
    self.pet_id = pet_id
    self.pet_name = pet_name

    self:on_pet_change():trigger(self, self.pet_id, self.pet_name)
end

-------
-- Returns the mob metadata for the party member's pet.
-- @treturn MobMetadata Full metadata for the party member's pet, or nil if it doesn't have a pet
function PartyMember:get_pet()
    if self.pet_id then
        return windower.ffxi.get_mob_by_id(self.pet_id)
    end
    local mob = self:get_mob()
    if mob and mob.pet_index then
        return windower.ffxi.get_mob_by_index(mob.pet_index)
    end
    return nil
end

-------
-- Sets the (x, y, z) coordinate of the mob.
-- @tparam number x X coordinate
-- @tparam number y Y coordinate
-- @tparam number z Z coordinate
function PartyMember:set_position(x, y, z)
    local last_position = self:get_position()
    if last_position[1] == x and last_position[2] == y and last_position[3] == z then
        return
    end
    Entity.set_position(self, x, y, z)

    self:on_position_change():trigger(self, x, y,  z)
end

-------
-- Returns the zone id of the party member. If the zone id is not set and the mob is non-nil, returns the player's current zone.
-- @treturn number Zone id (see res/zones.lua)
function PartyMember:get_zone_id()
    return self.zone_id
end

-------
-- Sets the zone id.
-- @tparam number zone_id Zone id (see res/zones.lua)
-- @tparam number zone_line (optional) Zone line, only set via IPC
-- @tparam number zone_type (optional) Zone type, only set via IPC
function PartyMember:set_zone_id(zone_id, zone_line, zone_type)
    zone_id = tonumber(zone_id)
    if (self.zone_id == zone_id and zone_line == nil and zone_type == nil) then
        return
    end
    logger.notice(self.__class, "set_zone_id", self:get_name(), zone_id, zone_line, zone_type)

    self.zone_id = zone_id
    self.last_zone_time = os.time()

    self:on_zone_change():trigger(self, zone_id, self:get_position()[1], self:get_position()[2], self:get_position()[3], tonumber(zone_line), tonumber(zone_type))
end

-------
-- Returns the last time the party member changed zones.
-- @treturn number Timestamp in seconds
function PartyMember:get_last_zone_time()
    return self.last_zone_time
end

-------
-- Returns the item id of the main weapon equipped.
-- @tparam number Item id of main weapon equipped (see res/items.lua)
function PartyMember:get_main_weapon_id()
    return self.main_weapon_id
end

-------
-- Sets the main weapon item id.
-- @tparam number main_weapon_id Item id (see res/items.lua)
function PartyMember:set_main_weapon_id(main_weapon_id)
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
function PartyMember:get_ranged_weapon_id()
    return self.ranged_weapon_id
end

-------
-- Sets the ranged weapon item id.
-- @tparam number ranged_weapon_id Item id (see res/items.lua)
function PartyMember:set_ranged_weapon_id(ranged_weapon_id)
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
function PartyMember:get_combat_skill_ids()
    return self.combat_skill_ids
end

-------
-- Sets the ranged weapon item id.
-- @tparam number ranged_weapon_id Item id (see res/items.lua)
function PartyMember:update_combat_skills()
    local combat_skill_ids = L{ self:get_main_weapon_id(), self:get_ranged_weapon_id() }:filter(function(weapon_id) return weapon_id ~= 0 end):compact_map():map(function(weapon_id)
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
-- Returns the battle stat tracker.
-- @treturn BattleStatTracker The battle stat tracker
function PartyMember:get_battle_stat_tracker()
    return self.battle_stat_tracker
end

-------
-- Returns the last heartbeat time.
-- @treturn number Last heartbeat time
function PartyMember:get_heartbeat_time()
    return self.heartbeat_time
end

-------
-- Sets the heartbeat time.
-- @tparam number time_in_sec Time
function PartyMember:set_heartbeat_time(time_in_sec)
    self.heartbeat_time = time_in_sec
end

return PartyMember