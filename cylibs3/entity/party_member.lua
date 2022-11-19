---------------------------
-- Wrapper class around a party member.
-- @class module
-- @name PartyMember

local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local packets = require('packets')
local res = require('resources')

local PartyMember = setmetatable({}, {__index = Entity })
PartyMember.__index = PartyMember

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

-------
-- Default initializer for a PartyMember.
-- @tparam number id Mob id
-- @treturn Player A player
function PartyMember.new(id)
    local self = setmetatable(Entity.new(id), PartyMember)
    self.id = id
    self.main_job_short = 'NON'
    self.sub_job_short = 'NON'
    self.hpp = 100
    self.hp = 0
    self.target_index = nil
    self.action_events = {}
    self.debuff_ids = S{}
    self.buff_ids = S{}
    self.is_monitoring = false
    self.heartbeat_time = os.time()

    self.target_change = Event.newEvent()
    self.gain_debuff = Event.newEvent()
    self.lose_debuff = Event.newEvent()
    self.gain_buff = Event.newEvent()
    self.lose_buff = Event.newEvent()

    if self:get_mob() then
        self.hpp = self:get_mob().hpp
    end

    self:update_debuffs(party_util.get_buffs(self.id))

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

    self.target_change:removeAllActions()
    self.gain_debuff:removeAllActions()
    self.lose_debuff:removeAllActions()
    self.gain_buff:removeAllActions()
    self.lose_buff:removeAllActions()
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function PartyMember:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.action_events.incoming = windower.register_event('incoming chunk', function(id, original, _, _, _)
        -- Update debuffs
        if id == 0x076 then
            self:update_debuffs(party_util.get_buffs(self.id))
            self:update_buffs(party_util.get_buffs(self.id))
        end
        -- Update target
        if id == 0x0DF then
            local p = packets.parse('incoming', original)
            if self:get_mob() and p.ID == self:get_mob().id and windower.ffxi.get_mob_by_id(p.ID) then
                if p.ID == windower.ffxi.get_player().id then
                    self:update_target(windower.ffxi.get_player().target_index)
                else
                    self:update_target(windower.ffxi.get_mob_by_id(p.ID).target_index)
                end
            end
        end
    end)
end

function PartyMember:update_target(target_index)
    if self.target_index ~= target_index then
        local old_target_index = self.target_index
        if target_index and target_index ~= 0 and battle_util.is_valid_monster_target(ffxi_util.mob_id_for_index(target_index)) then
            local target = windower.ffxi.get_mob_by_index(target_index)
            if target and party_util.party_claimed(target.id) then
                self.target_index = target.index
                self:on_target_change():trigger(self, self.target_index, old_target_index)
            end
        else
            self.target_index = nil
            self:on_target_change():trigger(self, self.target_index, old_target_index)
        end
    end
end

-------
-- Filters a list of buffs and updates the player's cached list of debuffs.
-- @tparam list List of buff ids (see buffs.lua)
function PartyMember:update_debuffs(buff_ids)
    local debuff_ids = S(buff_util.debuffs_for_buff_ids(buff_ids))

    local delta = set.sdiff(debuff_ids, self.debuff_ids)
    for buff_id in delta:it() do
        if debuff_ids:contains(buff_id) then
            self:on_gain_debuff():trigger(self, buff_id)
        else
            self:on_lose_debuff():trigger(self, buff_id)
        end
    end
    self.debuff_ids = debuff_ids
end

-------
-- Filters a list of buffs and updates the player's cached list of buffs.
-- @tparam list List of buff ids (see buffs.lua)
function PartyMember:update_buffs(buff_ids)
    local buff_ids = S(buff_util.buffs_for_buff_ids(buff_ids))
    local delta = set.sdiff(buff_ids, self.buff_ids)
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
-- Returns a list of the party member's debuffs.
-- @treturn list List of localized debuff names (see buffs.lua)
function PartyMember:get_debuffs()
    return L(self.debuff_ids:map(function(debuff_id)
        return res.buffs:with('id', debuff_id).enl
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
-- Returns true if the party member has the given debuff.
-- @tparam number debuff_id Debuff id (see buffs.lua)
-- @treturn boolean True if the party member has the given debuff, false otherwise
function PartyMember:has_debuff(debuff_id)
    return self.debuff_ids:contains(debuff_id)
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
-- Returns the player's current hit point percentage.
-- @treturn number Hit point percentage
function PartyMember:get_hpp()
    return self.hpp
end

-------
-- Returns the player's current hit point.
-- @treturn number Hit point
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
-- Returns whether the party member is alive.
-- @treturn Boolean True if the party member is alive, and false otherwise.
function PartyMember:is_alive()
    return self.hpp > 0
end

-------
-- Returns the party member's name.
-- @treturn string Party member's name
function PartyMember:get_name()
    return self:get_mob().name
end

-------
-- Returns whether this party member is a trust.
-- @treturn Boolean True if the party member is a trust, and false otherwise
function PartyMember:is_trust()
    return self:get_mob().is_npc
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