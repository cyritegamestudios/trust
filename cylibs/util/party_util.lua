---------------------------
-- Utility functions for parties and alliances.
-- @class module
-- @name party_util

_libs = _libs or {}

require('lists')

local table = require('table')
local packets = require('packets')
local player_util = require('cylibs/util/player_util')
local tables_ext = require('cylibs/util/extensions/tables')

local party_util = {}

_raw = _raw or {}

_libs.party_util = party_util

-------
-- Returns the party leader.
-- @treturn MobMetadata The mob data for the party leader, or nil if the player is not in a party.
function party_util.get_party_leader()
    local party_info = windower.ffxi.get_party()
    if party_info ~= nil then
        local party1_leader_id = party_info['party1_leader']
        if party1_leader_id ~= nil then
            local party1_leader = windower.ffxi.get_mob_by_id(party1_leader_id)
            if party1_leader and party1_leader.name == windower.ffxi.get_player().name then
                party1_leader = windower.ffxi.get_player()
            end
            return party1_leader
        end
    end
    local party_members = party_util.get_party_members()
    if party_members:length() == 1 --[[and not windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).in_party]] then
        return windower.ffxi.get_player()
    end
    return nil
end

-------
-- Determines if a mob is the leader of the player's party.
-- @param target_id Mob id
-- @treturn Boolean True if the mob is the party leader and false otherwise.
function party_util.is_party_leader(target_id)
    local party_leader = party_util.get_party_leader()
    if party_leader and party_leader.id == target_id then
        return true
    end
    return false
end

-------
-- Returns a list of party members.
-- @treturn list List of MobMetadata for party members, or an empty list if the player is not in a party
function party_util.get_party_members(include_alliance)
    local party_members = L{}
    for key, party_member in pairs(windower.ffxi.get_party()) do
        if type(party_member) == 'table' and party_member.mob then
            if party_member.mob.in_party or (party_member.mob.in_alliance and include_alliance) then
                party_members:append(party_member.mob)
            end
        end
    end
    return party_members
end

-------
-- Returns a list of parties in the alliance.
-- @treturn table Table mapping party member to a list of MobMetadata for party members in each party
function party_util.get_parties()
    local party_info = windower.ffxi.get_party()

    local parties = T{}

    parties[1] = party_util.get_party_members()

    local get_alliance_party = function(start_index, party_count)
        local party_members = {}
        for i = start_index, start_index + party_count do
            local party_member_info = party_info['a'..i]
            if party_member_info and party_member_info.mob then
                party_members:append(party_member_info.mob)
            end
        end
        return party_members
    end

    parties[2] = get_alliance_party(10, party_info.party2_count)
    parties[3] = get_alliance_party(20, party_info.party3_count)

    return parties
end

-------
-- Returns a party member with the given id.
-- @param target_id Mob id
-- @treturn MobMetadata MobMetada for the party member, if a party member with the given id is in the party
function party_util.get_party_member(target_id)
    local party_members = party_util.get_party_members()
    for party_member in party_members:it() do
        if party_member.id == target_id then
            return party_member
        end
    end
    return nil
end

-------
-- Determines if a mob is a member of the player's party.
-- @param target_id Mob id
-- @treturn Boolean True if the mob is in the party and false otherwise.
function party_util.is_party_member(target_id)
    local target = windower.ffxi.get_mob_by_id(target_id)
    if target then
        return target.in_party
    end
    return false
end

-------
-- Determines if a mob is claimed by the player or a member of the player's party.
-- @param number target_id Mob id
-- @param list party_member_ids (optional) Filter by mobs claimed by these party members
-- @treturn Boolean True if the mob is claimed by the player's party and false otherwise.
function party_util.party_claimed(target_id, party_member_ids)
    if target_id == nil then return false end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if target ~= nil and target.claim_id ~= nil and target.claim_id ~= 0 then
        local claimed_by = windower.ffxi.get_mob_by_id(target.claim_id)
        if claimed_by ~= nil and player_util.player_in_party(claimed_by.name) and (party_member_ids == nil or party_member_ids:contains(claimed_by.id)) then
            return true
        end
    end
    return false
end

-------
-- Returns all nearby mobs that are party claimed.
-- @param number range_check Range check (optional)
-- @param list party_member_ids (optional) Filter by mobs claimed by these party members
-- @treturn list A list of indices of all mobs currently targeted by party members.
function party_util.get_party_claimed_mobs(range_check, party_member_ids)
    local party_claimed_mobs = L{}

    local nearby_mobs = windower.ffxi.get_mob_array()
    for _, target in pairs(nearby_mobs) do
        if target and target.distance:sqrt() < (range_check or 15) and target.hpp > 0 and target.status ~= 3 and party_util.party_claimed(target.id, party_member_ids) then
            if target ~= nil then
                party_claimed_mobs:append(target.index)
            end
        end
    end
    return party_claimed_mobs
end

-------
-- Determines if a mob is claimed by a player outside of the player's party.
-- @param target_id Mob id
-- @treturn Boolean True if the mob is claimed by a player outside of the player's party.
function party_util.not_party_claimed(target_id)
    if target_id == nil then return false end

    local target = windower.ffxi.get_mob_by_id(target_id)
    if target ~= nil and target.claim_id ~= nil and target.claim_id ~= 0 then
        local claimed_by = windower.ffxi.get_mob_by_id(target.claim_id)
        if claimed_by then
            return not party_util.is_party_member(claimed_by.id)
        end
    end
    return false
end

-------
-- Determines if a mob is targeting the player or a member of the player's party.
-- @param target_id Mob id
-- @treturn Boolean True if the mob is targeting a player or a member of the player's party and false otherwise.
function party_util.party_targeted(target_id)
    local mob = windower.ffxi.get_mob_by_id(target_id)
    if mob and mob.target_index then
        local target = windower.ffxi.get_mob_by_index(mob.target_index)
        if target then
            return party_util.is_party_member(target.id)
        end
    end
    return false
end

-------
-- Returns all nearby mobs that are targeting party members.
-- @treturn list A list of indices of all mobs currently targeting party members.
function party_util.get_mobs_targeting_party()
    local mobs_targeting_party = L{}

    local nearby_mobs = windower.ffxi.get_mob_array()
    for _, target in pairs(nearby_mobs) do
        if target and target.hpp > 0 and target.status ~= 3 and party_util.party_targeted(target.id) then
            mobs_targeting_party:append(target.index)
        end
    end
    return mobs_targeting_party
end

-------
-- Returns a list of indices of all mobs currently targeted by party members. The mobs do not have to be claimed as
-- long as the target_index field of a party member's MobMetadata is not nil.
-- @treturn list A list of indices of all mobs currently targeted by party members.
function party_util.party_targets(exclude_id)
    local target_indices = L{}
    for _, party_member in pairs(windower.ffxi.get_party()) do
        if type(party_member) == 'table' and party_member.mob and party_member.name ~= windower.ffxi.get_player().name then
            if party_member.mob.target_index and (exclude_id == nil or party_member.id ~= exclude_id) then
                target_indices:append(party_member.mob.target_index)
            end
        end
    end
    return target_indices
end

---- A cache of party member buffs.
-- @table Buffs
-- @tfield T whitelist A map of target id to a list of buff ids
-- @tfield Data last_incoming The packet data for the last 0x076 packet received
local buffs = T{}
buffs.whitelist = {}
buffs.last_incoming = nil

-------
-- Returns a list of buff ids for a party member (see buffs.lua).
-- @param target_id Mob id
-- @treturn list A list of buff ids for a party member, or an empty list if the target is not in the player's party.
function party_util.get_buffs(target_id)
    if target_id == windower.ffxi.get_player().id then
        return L(windower.ffxi.get_player().buffs)
    end
    local data = windower.packets.last_incoming(0x076)
    if data and data ~= buffs.last_incoming then
        buffs.last_incoming = data
        for  k = 0, 4 do
            local id = data:unpack('I', k*48+5)
            buffs['whitelist'][id] = T{}

            if id ~= 0 then
                for i = 1, 32 do
                    local buff = data:byte(k*48+5+16+i-1) + 256*( math.floor( data:byte(k*48+5+8+ math.floor((i-1)/4)) / 4^((i-1)%4) )%4) -- Credit: Byrth, GearSwap
                    if buffs['whitelist'][id][i] ~= buff then
                        buffs['whitelist'][id][i] = buff
                    end
                end
            end
        end
    end
    if buffs['whitelist'][target_id] then
        return L{buffs['whitelist'][target_id]:unpack()}:filter(function(v) return v~= 255  end)
    end
    return L{}
end

-------
-- Returns whether the target is an alter ego.
-- @param target_name string Mob name
-- @treturn Boolean True if the target is an alter ego
function party_util.is_alter_ego(target_name)
    local trusts = require('cylibs/res/trusts')
    local trust_names = L(res.spells:with_all('type', 'Trust'):map(function(trust) return trust.name end))
    return trust_names:contains(target_name) or trust_names:contains(target_name..' (UC)') or trusts:with('enl', target_name)
end

return party_util