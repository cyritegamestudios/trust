---------------------------
-- Wrapper class around an alliance.
-- @class module
-- @name Alliance

local AllianceMember = require('cylibs/entity/alliance/alliance_member')
local DisposeBag = require('cylibs/events/dispose_bag')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local list_ext = require('cylibs/util/extensions/lists')
local Party = require('cylibs/entity/party')

local Alliance = setmetatable({}, {__index = Entity })
Alliance.__index = Alliance
Alliance.__class = "Alliance"

-- Event called when a party is added to the alliance.
function Party:on_party_added()
    return self.party_added
end

-- Event called when a party is removed from the alliance.
function Party:on_party_removed()
    return self.party_removed
end

-- Event called when the alliance is dissolved.
function Party:on_alliance_dissolved()
    return self.alliance_dissolved
end

-------
-- Default initializer for an Alliance.
-- @treturn Alliance An alliance
function Alliance.new(party_chat)
    local self = setmetatable(Entity.new(0), Alliance)

    self.is_monitoring = false
    self.events = {}
    self.parties = L{}
    self.alliance_members_list = T{}
    self.pending_party_member_ids = S{}
    self.dispose_bag = DisposeBag.new()

    self.party_added = Event.newEvent()
    self.party_removed = Event.newEvent()
    self.alliance_dissolved = Event.newEvent()

    for _ = 1, 3 do
        self.parties:append(Party.new(party_chat))
    end

    --local player = windower.ffxi.get_player()
    --self:get_parties()[1]:add_party_member(player.id, player.name)

    self.dispose_bag:addAny(self:get_parties())

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Alliance:destroy()
    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end

    self:on_party_added():removeAllActions()
    self:on_party_removed():removeAllActions()
    self:on_alliance_dissolved():removeAllActions()

    self.dispose_bag:destroy()
end

-------
-- Starts monitoring the alliance.
function Alliance:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    for party in self:get_parties():it() do
        party:monitor()
    end

    -- Add placeholders for alliance members until id can be mapped to name
    self.dispose_bag:add(WindowerEvents.AllianceMemberListUpdate:addAction(function(alliance_members_list)
        self.alliance_members_list = T{}

        for alliance_member in alliance_members_list:it() do
            self.alliance_members_list[alliance_member.id] = alliance_member
            if alliance_member:get_mob() then
                local party = self:get_parties()[alliance_member:get_party_index()]
                if party then
                    party:add_party_member(alliance_member:get_id(), alliance_member:get_name())
                end
            end
        end

        local new_member_ids = self.alliance_members_list:keyset()
        local old_member_ids = self:get_alliance_members():map(function(alliance_member) return alliance_member:get_id() end)

        local delta = list.diff(old_member_ids, new_member_ids)
        for alliance_member_id in delta:it() do
            if not new_member_ids:contains(alliance_member_id) then
                for party in self:get_parties():it() do
                    if party:has_party_member(alliance_member_id) then
                        party:remove_party_member(alliance_member_id)
                    end
                end
            end
        end
    end), WindowerEvents.AllianceMemberListUpdate)

    -- Add pending alliance members to their respective parties
    self.dispose_bag:add(WindowerEvents.CharacterUpdate:addAction(function(mob_id, name, hp, hpp, mp, mpp, tp, main_job_id, sub_job_id)
        local alliance_member = self.alliance_members_list[mob_id]
        if alliance_member then
            local party = self:get_party(name) or self:get_parties()[alliance_member:get_party_index()]
            if party and not party:has_party_member(mob_id) then
                logger.notice(self.__class, "character update", "adding", name, "to party at index", self:get_party_index(name))
                local party_member = party:add_party_member(mob_id, name)
                party_member:set_zone_id(alliance_member:get_zone_id())
            end
        end
    end), WindowerEvents.CharacterUpdate)

    self.events.zone_change = windower.register_event('zone change', function(new_zone_id, old_zone_id)
        for party in self.parties:it() do
            local party_members_to_remove = L{}
            for party_member in party:get_party_members(false):it() do
                if party_member:is_trust() then
                    party_members_to_remove:append(party_member)
                end
            end
            for party_member in party_members_to_remove:it() do
                party:remove_party_member(party_member:get_id())
            end
        end
    end)

    WindowerEvents.replay_last_events(L{ WindowerEvents.AllianceMemberListUpdate })
end

-------
-- Returns all members in the alliance.
-- @treturn list List of all PartyMember in the alliance
function Alliance:get_alliance_members()
    local alliance_members = L{}
    for party in self.parties:it() do
        alliance_members = alliance_members:extend(party:get_party_members(true))
    end
    return alliance_members
end

-------
-- Returns a member of the alliance with the given name.
-- @tparam string alliance_member_name Name of alliance member
-- @tparam boolean ignore_range_check If true, will not require mob to be non-nil
-- @treturn PartyMember Party member, or nil if member is not in the alliance
function Alliance:get_alliance_member_named(alliance_member_name, ignore_range_check)
    local party = self:get_party(alliance_member_name)
    if party then
        return party:get_party_member_named(alliance_member_name, ignore_range_check)
    end
    return nil
end

-------
-- Returns the party of the alliance member with the given name.
-- @tparam string alliance_member_name Name of alliance member
-- @treturn Party Party that the alliance member is in, or nil if not in the alliance
function Alliance:get_party(alliance_member_name)
    local party_index = self:get_party_index(alliance_member_name)
    if party_index then
        return self:get_parties()[party_index]
    end
    return nil
end

-------
-- Returns the party index of the alliance member with the given name.
-- @tparam string alliance_member_name Name of alliance member
-- @treturn number Index of the party that the alliance member is in, or nil if not in the alliance
function Alliance:get_party_index(alliance_member_name)
    local party_index
    for key, party_member in pairs(windower.ffxi.get_party()) do
        if type(party_member) == 'table' then
            if party_member.name == alliance_member_name then
                if string.match(key, "p[0-5]") then
                    party_index = 1
                    break
                elseif string.match(key, "a[10-15]") then
                    party_index = 2
                    break
                elseif string.match(key, "a[20-25]") then
                    party_index = 3
                    break
                end
            end
        end
    end
    return party_index
end

-------
-- Returns the list of parties in the alliance.
-- @treturn list List of Party (see party.lua)
function Alliance:get_parties()
    return self.parties
end

return Alliance