---------------------------
-- Wrapper class around a party.
-- @class module
-- @name Party

local AlterEgo = require('cylibs/entity/alter_ego')
local DisposeBag = require('cylibs/events/dispose_bag')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local monster_util = require('cylibs/util/monster_util')
local MobTracker = require('cylibs/battle/monsters/mob_tracker')
local PartyMember = require('cylibs/entity/party_member')
local Player = require('cylibs/entity/party/player')
local party_util = require('cylibs/util/party_util')

local Party = setmetatable({}, {__index = Entity })
Party.__index = Party
Party.__class = "Party"

-- Event called when the party member is added.
function Party:on_party_member_added()
    return self.party_member_added
end

-- Event called when the party member is removed.
function Party:on_party_member_removed()
    return self.party_member_removed
end

-- Event called when a party member is added or removed.
function Party:on_party_members_changed()
    return self.party_members_changed
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
-- @tparam PartyChat party_chat Party chat to send messages to
-- @treturn Party A party
function Party.new(party_chat)
    local self = setmetatable(Entity.new(0), Party)

    self.party_chat = party_chat
    self.is_monitoring = false
    self.party_members = T{}
    self.dispose_bag = DisposeBag.new()
    self.assist_target_dispose_bag = DisposeBag.new()
    self.action_events = {}

    self.party_member_added = Event.newEvent()
    self.party_member_removed = Event.newEvent()
    self.party_members_changed = Event.newEvent()
    self.target_change = Event.newEvent()
    self.assist_target_change = Event.newEvent()

    self.target_tracker = MobTracker.new(self:on_party_member_added(), self:on_party_member_removed())

    self.dispose_bag:addAny(L{ self.target_tracker, self.assist_target_dispose_bag })

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Party:destroy()
    for party_member in self:get_party_members(true):it() do
        party_member:destroy()
    end

    for _, event in pairs(self.action_events) do
        windower.unregister_event(event)
    end

    self:on_party_member_added():removeAllActions()
    self:on_party_member_removed():removeAllActions()
    self:on_party_members_changed():removeAllActions()
    self:on_party_target_change():removeAllActions()
    self:on_party_assist_target_change():removeAllActions()

    self.dispose_bag:destroy()
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Party:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.target_tracker:monitor()

    self.action_events.zone_change = windower.register_event('zone change', function(_, _)
        self:on_party_target_change():trigger(self, nil, nil)
    end)
end

-------
-- Adds a member to the party if they aren't in the party already, and updates the party member's main/sub job if they are.
-- @tparam number party_member_id Party member id
-- @tparam boolean is_alter_ego Whether the party member is an alter ego
function Party:add_party_member(party_member_id, party_member_name)
    if self:has_party_member(party_member_id) then
        return self.party_members[party_member_id]
    end

    if party_util.is_alter_ego(party_member_name) then
        self.party_members[party_member_id] = AlterEgo.new(party_member_id, party_member_name)
    elseif party_member_id == windower.ffxi.get_player().id then
        self.party_members[party_member_id] = Player.new(party_member_id)
    else
        self.party_members[party_member_id] = PartyMember.new(party_member_id, party_member_name)
    end

    local party_member = self.party_members[party_member_id]

    party_member:monitor()
    --party_member:on_target_change():addAction(function(p, new_target_index, old_target_index)
    --    logger.notice(self.__class, 'on_target_change', p:get_name(), new_target_index)
    --    if self:get_assist_target() and self:get_assist_target():is_valid() and p:get_name() == self:get_assist_target():get_name() then
    --        self:on_party_target_change():trigger(self, new_target_index, old_target_index)
    --    end
    --end)

    self:on_party_member_added():trigger(party_member)
    self:on_party_members_changed():trigger(self:get_party_members(true))

    self.target_tracker:add_mob_by_index(party_member:get_target_index())

    logger.notice(self.__class, "add_party_member", party_member:get_name(), party_member_id)

    return party_member
end

-------
-- Removes a party member from the party.
-- @tparam number party_member_id Party member id
function Party:remove_party_member(party_member_id)
    if self:get_assist_target() and self:get_assist_target():get_id() == party_member_id then
        self:set_assist_target(self:get_player())
    end

    local party_member = self.party_members[party_member_id]
    if party_member then
        party_member:destroy()

        self.party_members[party_member_id] = nil

        self:on_party_member_removed():trigger(party_member)
        self:on_party_members_changed():trigger(self:get_party_members(true))
    end

    logger.notice(self.__class, "remove_party_member", party_member:get_name(), party_member_id)
end

-------
-- Returns whether a player with the given id is in the party.
-- @tparam number party_member_id Party member id
-- @treturn boolean True if the player is in the party
function Party:has_party_member(party_member_id)
    if party_member_id == nil then
        return false
    end
    return self.party_members[party_member_id] ~= nil
end

-------
-- Returns whether a player with the given name is in the party.
-- @tparam string party_member_name Party member name
-- @treturn boolean True if the player is in the party
function Party:has_party_member_named(party_member_name)
    if party_member_name == nil then
        return false
    end
    return self:get_party_member_named(party_member_name, true) ~= nil
end

-------
-- Returns all party members, optionally including the player.
-- @tparam Boolean include_self If true, the player will be returned
-- @tparam number range_check If non-nil, only returns party members that are < range_check yalms away from the player
-- @treturn list Party members
function Party:get_party_members(include_self, range_check)
    local party_members = L{}
    for _, party_member in pairs(self.party_members) do
        if --[[party_member:get_mob() and ]](party_member:get_id() ~= windower.ffxi.get_player().id or include_self)
                and (range_check == nil or party_member:get_distance():sqrt() < range_check) then
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
        if party_member:get_id() == mob_id or party_member:get_pet() and party_member:get_pet().id == mob_id then
            return party_member
        end
    end
    return nil
end

-------
-- Returns the party member with the given name.
-- @tparam string mob_name Party member mob name
-- @tparam boolean ignore_range_check If true, will not require mob to be non-nil
-- @treturn PartyMember Party member, or nil if none exists
function Party:get_party_member_named(mob_name, ignore_range_check)
    for _, party_member in pairs(self.party_members) do
        if (party_member:get_mob() and party_member:get_mob().name == mob_name)
                or ignore_range_check and party_member:get_name() == mob_name then
            return party_member
        end
    end
    return nil
end

-------
-- Returns the party member for the player.
-- @treturn PartyMember Party member for the player, or nil if none exists
function Party:get_player()
    return self:get_party_member(windower.ffxi.get_player().id)
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
                self.party_members[party_member:get_id()] = nil
                self.target_tracker:remove_player(party_member:get_id())
                coroutine.schedule(function()
                    self:on_party_member_removed():trigger(party_member)
                    party_member:destroy()
                    self:on_party_members_changed():trigger(self:get_party_members(true))
                end, 1)
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
    if self.assist_target and self.assist_target:get_id() == party_member:get_id() then
        if self.assist_target:get_id() ~= windower.ffxi.get_player().id then
            self:add_to_chat(self:get_player(), "I'm already assisting "..party_member:get_name().."!")
        end
        return
    end
    self.assist_target = party_member
    self.assist_target_dispose_bag:dispose()

    if party_member then
        self.assist_target_dispose_bag:add(party_member:on_target_change():addAction(function(p, new_target_index, old_target_index)
            logger.notice(self.__class, 'set_assist_target', 'on_target_change', p:get_name(), new_target_index)
            if self:get_assist_target() and self:get_assist_target():is_valid() and p:get_name() == self:get_assist_target():get_name() then
                logger.notice(self.__class, 'set_assist_target', 'on_party_target_change', p:get_name(), new_target_index)
                self:on_party_target_change():trigger(self, new_target_index, old_target_index)
            end
        end), party_member:on_target_change())

        local party_targets = self.target_tracker:get_targets():filter(function(m) return m:is_claimed() end)
        local initial_target_index = party_member:get_target_index() or party_targets:length() > 0 and party_targets[1]:get_mob().index
        if initial_target_index then
            self:on_party_target_change():trigger(self, initial_target_index, nil)
        end
        logger.notice(self.__class, 'set_assist_target', party_member:get_name(), initial_target_index)

        if party_member:get_name() ~= windower.ffxi.get_player().name then
            self:add_to_chat(self:get_player(), "Okay, I'll assist "..party_member:get_name().." in battle.")
        end
    end
    self:on_party_assist_target_change():trigger(self, self.assist_target)
end

-------
-- Returns the assist target of the party.
-- @treturn PartyMember Assist target
function Party:get_assist_target()
    return self.assist_target or self:get_party_member(windower.ffxi.get_player().id)
end

-------
-- Returns the current party target.
-- @treturn Monster Current party target, or nil if none.
function Party:get_current_party_target()
    local assist_target = self:get_assist_target()
    if assist_target and assist_target:is_valid() and assist_target:get_target_index() then
        local current_target = self.target_tracker:get_mob(monster_util.id_for_index(assist_target:get_target_index()))
        if current_target then
            return current_target
        end
    end
    return nil
end

-------
-- Returns a mob being targeted by the party.
-- @tparam number target_id Target id
-- @treturn Monster Target, or nil if not a party target
function Party:get_target(target_id)
    return self.target_tracker:get_mob(target_id)
end

-------
-- Returns a mob being targeted by the party.
-- @tparam number target_index Target index
-- @treturn Monster Target, or nil if not a party target
function Party:get_target_by_index(target_index)
    return self:get_target(monster_util.id_for_index(target_index))
end

-------
-- Returns all party targets.
-- @tparam function filter (optional) Function to filter targets
-- @treturn list List of Monsters
function Party:get_targets(filter)
    filter = filter or function(t) return true  end
    return self.target_tracker:get_targets():filter(function(t) return filter(t) end)
end

-------
-- Returns all party targets.
-- @tparam function filter (optional) Function to filter targets
-- @treturn list List of Monsters
function Party:get_target_tracker()
    return self.target_tracker
end

-------
-- Sends a message to the party chat.
-- @tparam PartyMember Message sender
-- @tparam string Message
function Party:add_to_chat(party_member, message, throttle_key, throttle_duration, is_local_only)
    self.party_chat:add_to_chat(party_member:get_name(), message, throttle_key, throttle_duration, is_local_only)
end

return Party