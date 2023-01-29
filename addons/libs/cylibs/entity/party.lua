---------------------------
-- Wrapper class around a party.
-- @class module
-- @name Party

local AlterEgo = require('cylibs/entity/alter_ego')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local packets = require('packets')
local PartyMember = require('cylibs/entity/party_member')
local res = require('resources')
local trusts = require('cylibs/res/trusts')

local Party = setmetatable({}, {__index = Entity })
Party.__index = Party

-- Event called when a party member's HP changes.
function Party:on_party_member_hp_change()
    return self.hp_change
end

-- Event called when a party member is knocked out.
function Party:on_party_member_ko()
    return self.party_member_ko
end

-- Event called when a party member's MP changes.
function Party:on_party_member_mp_change()
    return self.mp_change
end

-- Event called when the party's target changes.
function Party:on_party_target_change()
    return self.target_change
end

-- Event called when the party's assist target changes.
function Party:on_party_assist_target_change()
    return self.assist_target_change
end

-------
-- Default initializer for a Party.
-- @treturn Party A party
function Party.new()
    local self = setmetatable(Entity.new(0), Party)
    self.id = id
    self.action_events = {}
    self.is_monitoring = false
    self.party_members = T{}

    self.hp_change = Event.newEvent()
    self.mp_change = Event.newEvent()
    self.party_member_ko = Event.newEvent()
    self.target_change = Event.newEvent()
    self.assist_target_change = Event.newEvent()

    for party_member in party_util.get_party_members():it() do
        self:add_member(party_member.id, party_member.name)
    end

    self.assist_target = self:get_party_member(windower.ffxi.get_player().id)

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Party:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    for party_member in self:get_party_members(true):it() do
        party_member:destroy()
    end

    self:on_party_member_hp_change():removeAllActions()
    self:on_party_member_mp_change():removeAllActions()
    self:on_party_member_ko():removeAllActions()
    self:on_party_target_change():removeAllActions()
    self:on_party_assist_target_change():removeAllActions()
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Party:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    -- Update party members
    self.action_events.incoming = windower.register_event('incoming chunk', function(id, original, _, _, _)
        if id == 0x0DF then
            local p = packets.parse('incoming', original)

            local mob_id = p['ID']
            local hpp = p['HPP']
            local hp = p['HP']
            local main_job_id = p['Main job']
            local sub_job_id = p['Sub job']

            if mob_id and hpp and self.party_members[mob_id] and self.party_members[mob_id]:get_mob() then
                self:add_member(mob_id, self.party_members[mob_id]:get_name(), main_job_id, sub_job_id, hpp, hp)

                if hpp > 0 then
                    self:on_party_member_hp_change():trigger(self.party_members[mob_id], hpp, hp / (hpp / 100.0))
                else
                    self:on_party_member_ko():trigger(self.party_members[mob_id])
                end
            end

            self:prune_party_members()
        elseif id == 0x0DD then
            -- called when party member is added (and removed?)
            local p = packets.parse('incoming', original)

            local mob_id = p['ID']
            local hpp = p['HP%']
            local hp = p['HP']
            local main_job_id = p['Main job']
            local sub_job_id = p['Sub job']
            local name = p['Name']

            self:add_member(mob_id, name, main_job_id, sub_job_id, hpp, hp)
        end
    end)
end

-------
-- Adds a member to the party if they aren't in the party already, and updates the party member's main/sub job if they are.
-- @tparam number mob_id Party member id
-- @tparam string name Name of party member
-- @tparam number main_job_id Optional main job id
-- @tparam number sub_job_id Optional sub job id
-- @tparam number hpp Current hit point percentage
-- @tparam number hp Current hit points
function Party:add_member(mob_id, name, main_job_id, sub_job_id, hpp, hp)
    if mob_id and not self.party_members[mob_id] then
        if party_util.is_alter_ego(name) then
            self.party_members[mob_id] = AlterEgo.new(mob_id)
        else
            self.party_members[mob_id] = PartyMember.new(mob_id)
        end
        self.party_members[mob_id]:monitor()
        self.party_members[mob_id]:on_target_change():addAction(function(p, new_target_index, old_target_index)
            if self:get_assist_target():is_valid() and p:get_name() == self:get_assist_target():get_name() then
                self:on_party_target_change():trigger(self, new_target_index, old_target_index)
            end
        end)
        if not self.party_members[mob_id]:is_alive() then
            self:on_party_member_ko():trigger(self.party_members[mob_id])
        end
    end

    local party_member = self.party_members[mob_id]

    party_member.hpp = hpp or party_member:get_mob().hpp
    party_member.hp = hp or 0
    party_member:set_heartbeat_time(os.time())

    if not party_member:is_trust() then
        if main_job_id then
            party_member.main_job_short = res.jobs[main_job_id]['ens']
        end
        if sub_job_id then
            party_member.sub_job_short = res.jobs[sub_job_id]['ens']
        end
    else
        if party_member:get_mob() then
            local trust = trusts:with('en', party_member:get_name())
            if trust then
                party_member.main_job_short = trust.main_job_short
                party_member.sub_job_short = trust.sub_job_short
            end
        end
    end
end

-------
-- Returns all party members, optionally including the player.
-- @tparam Boolean include_self If true, the player will be returned
-- @tparam number range_check If non-nil, only returns party members that are < range_check yalms away from the player
-- @treturn list Party members
function Party:get_party_members(include_self, range_check)
    local party_members = L{}
    for _, party_member in pairs(self.party_members) do
        if party_member:get_mob() and (party_member:get_mob().id ~= windower.ffxi.get_player().id or include_self)
                and (range_check == nil or party_member:get_mob().distance:sqrt() < range_check) then
            party_members:append(party_member)
        end
    end
    return party_members
end

-------
-- Returns the party member with the given mob id.
-- @tparam number mob_id Party member mob id
-- @treturn PartyMember Party member, or nil if none exists
function Party:get_party_member(mob_id)
    for _, party_member in pairs(self.party_members) do
        if party_member:get_mob() and party_member:get_mob().id == mob_id then
            return party_member
        end
    end
    return nil
end

-------
-- Returns the party member with the given name.
-- @tparam string mob_name Party member mob name
-- @treturn PartyMember Party member, or nil if none exists
function Party:get_party_member_named(mob_name)
    for _, party_member in pairs(self.party_members) do
        if party_member:get_mob() and party_member:get_mob().name == mob_name then
            return party_member
        end
    end
    return nil
end

-------
-- Checks to see if each party member is still in the party. Removes invalid party members.
function Party:prune_party_members()
    local current_time = os.time()
    for party_member in self:get_party_members(true):it() do
        if current_time - party_member:get_heartbeat_time() > 5 then
            if not party_member:get_mob() or not party_util.is_party_member(party_member:get_id()) then
                if party_member:get_id() == self:get_assist_target():get_id() then
                    self:set_assist_target(self:get_party_member(windower.ffxi.get_player().id))
                end
                party_member:destroy()
                self.party_members[party_member:get_id()] = nil
            end
        end
    end
end

-------
-- Returns the number of party members.
-- @treturn number Number of party members
function Party:num_party_members()
    return #L(self.party_members:keyset())
end

-------
-- Sets the assist target. The party's target will change to match the assist target.
-- @tparam PartyMember party_member Party member to assist
function Party:set_assist_target(party_member)
    self.assist_target = party_member
    self:on_party_assist_target_change():trigger(self, self.assist_target)
end

-------
-- Returns the assist target of the party.
-- @treturn PartyMember Assist target
function Party:get_assist_target()
    return self.assist_target or self:get_party_member(windower.ffxi.get_player().id)
end


return Party